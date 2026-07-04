import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Loads bundled Quran assets from `assets/data/`.
class DSLocalQuran {
  DSLocalQuran();

  static const _surahsPath = 'assets/data/surahs.json';
  static String _pagePath(int page) => 'assets/data/mushaf_pages/page-${page.toString().padLeft(3, '0')}.json';

  List<MSurah>? _surahsCache;
  final Map<int, MPageLayout> _pageCache = {};

  Future<List<MSurah>> loadSurahs() async {
    if (_surahsCache != null) return _surahsCache!;
    final raw = await rootBundle.loadString(_surahsPath);
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MSurah.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    _surahsCache = list;
    return list;
  }

  Future<MPageLayout> loadPage(int page) async {
    final cached = _pageCache[page];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_pagePath(page));
    final layout = MPageLayout.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    _pageCache[page] = layout;
    // Cap the cache so we don't hold all 604 pages — keep last 12 visited.
    if (_pageCache.length > 12) {
      final firstKey = _pageCache.keys.first;
      _pageCache.remove(firstKey);
    }
    return layout;
  }

  /// Loads the page layout for the active [mode]. All modes now share the base
  /// QPC layout: V1/V2 render its word-glyphs, and Tajweed (Approach B) only
  /// needs the page number from it — its coloured text comes from the separate
  /// token dataset (`DSLocalTajweed`), not the old `mushaf_v4` layout.
  Future<MPageLayout> loadPageForMode(int page, EQuranFontMode mode) =>
      loadPage(page);

  /// Find which page contains (surah, ayah). Falls back to surah.pageStart.
  Future<int> pageOfAyah(int surah, int ayah) async {
    final surahs = await loadSurahs();
    final s = surahs.firstWhere((e) => e.number == surah, orElse: () => surahs.first);
    // Scan from pageStart forward; usually within 2-3 pages.
    var page = s.pageStart;
    if (page <= 0) return 1;
    while (page <= 604) {
      final layout = await loadPage(page);
      final hit = layout.allAyahRefs.any((r) => r.surah == surah && r.ayah == ayah);
      if (hit) return page;
      // Stop early if this page belongs to a later surah and ayah wasn't found
      final maxSurah = layout.allAyahRefs.isEmpty
          ? surah
          : layout.allAyahRefs.map((r) => r.surah).reduce((a, b) => a > b ? a : b);
      if (maxSurah > surah) return page; // ayah out of range — return closest
      page++;
    }
    return s.pageStart;
  }

  /// Returns the plain Uthmani text for one ayah without building the full
  /// search index.
  Future<String> ayahText(ParamAyahRef ref) async {
    final page = await pageOfAyah(ref.surah, ref.ayah);
    final layout = await loadPage(page);
    final words = <String>[];
    for (final line in layout.lines) {
      for (final word in line.words) {
        if (word.surah == ref.surah && word.ayah == ref.ayah) {
          words.add(word.word);
        }
      }
    }
    return words.join(' ');
  }

  /// Full Uthmani text for one ayah, correctly aggregated even when the verse
  /// spans more than one page. Unlike [ayahText] it keeps walking forward from
  /// the start page until a page contributes no more words for the ayah.
  Future<String> fullAyahText(ParamAyahRef ref) async {
    final start = await pageOfAyah(ref.surah, ref.ayah);
    final words = <String>[];
    for (var page = start; page <= 604; page++) {
      final layout = await loadPage(page);
      final before = words.length;
      for (final line in layout.lines) {
        for (final word in line.words) {
          if (word.surah == ref.surah && word.ayah == ref.ayah) {
            words.add(word.word);
          }
        }
      }
      // Once we've started collecting, a page that adds nothing means the ayah
      // has ended — stop before reading the rest of the mushaf.
      if (words.isNotEmpty && words.length == before) break;
    }
    return words.join(' ');
  }

  /// Picks a single ayah deterministically for the calendar [day] and returns
  /// it together with its surah. The same day always yields the same verse, and
  /// consecutive days are spread across the whole mushaf via a hash so the
  /// "verse of the day" doesn't simply walk forward one ayah at a time.
  ///
  /// [maxChars] caps how long the chosen verse may be so it fits the home
  /// "verse of the day" card without ellipsis, and [minChars] rejects verses
  /// too short to be meaningful (e.g. single-word ayat). Length is measured on
  /// the diacritic-stripped text (a closer proxy for rendered width than the raw
  /// Uthmani string, since harakat add glyphs but little width). When no
  /// candidate fits within the attempt budget, the primary day-pick is used.
  Future<({ParamAyahRef ref, MSurah surah, String text})> dailyVerse(
    DateTime day, {
    int maxChars = 80,
    int minChars = 10,
  }) async {
    final surahs = await loadSurahs();
    final total = surahs.fold<int>(0, (sum, s) => sum + s.totalAyah);
    final dayNumber = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(1970)).inDays;

    // Resolve a global 0-based ayah index to its surah + 1-based ayah number.
    ({MSurah surah, int ayah}) locate(int globalIndex) {
      var running = globalIndex;
      for (final s in surahs) {
        if (running < s.totalAyah) return (surah: s, ayah: running + 1);
        running -= s.totalAyah;
      }
      return (surah: surahs.first, ayah: 1);
    }

    // Probe deterministically-spread candidates until one fits the card. Each
    // attempt re-hashes (Knuth multiplicative) to a different part of the
    // mushaf so we don't just walk into the long verse next to a long verse.
    // Attempt 0 is the stable "primary" pick and the fallback if nothing fits.
    late ParamAyahRef ref;
    late MSurah chosen;
    late String text;
    const maxAttempts = 40;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final pick = (((dayNumber + attempt * 7919) * 2654435761) & 0x7fffffffffff) % total;
      final hit = locate(pick);
      final r = ParamAyahRef(surah: hit.surah.number, ayah: hit.ayah);
      final t = _stripAyahNumbers(await fullAyahText(r));
      if (attempt == 0) {
        ref = r;
        chosen = hit.surah;
        text = t;
      }
      final len = _normalise(t).length;
      if (len > minChars && len <= maxChars) {
        ref = r;
        chosen = hit.surah;
        text = t;
        break;
      }
    }

    return (ref: ref, surah: chosen, text: text);
  }

  /// Removes the trailing Arabic-Indic ayah-number glyph (and any stray digits)
  /// from Uthmani verse text — the number is shown separately in the caption.
  static String _stripAyahNumbers(String input) {
    final buf = StringBuffer();
    for (final code in input.runes) {
      // Arabic-Indic (0x0660..0x0669) and extended (0x06F0..0x06F9) digits.
      if ((code >= 0x0660 && code <= 0x0669) || (code >= 0x06F0 && code <= 0x06F9)) {
        continue;
      }
      buf.writeCharCode(code);
    }
    // Collapse the double spaces left where a number was removed.
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Plain Uthmani text per ayah, keyed by `"surah:ayah"`. Built once by
  /// streaming through all 604 page JSONs and aggregating words; cached
  /// for the rest of the session.
  Map<String, String>? _ayahTextIndex;
  Map<String, String>? _ayahNormalisedIndex;
  Map<String, int>? _ayahPageIndex;
  Future<Map<String, String>>? _buildingIndex;

  /// Returns the full ayah-text index, building it lazily on first call.
  Future<Map<String, String>> ayahTextIndex() {
    final existing = _ayahTextIndex;
    if (existing != null) return Future.value(existing);
    return _buildingIndex ??= _buildIndex();
  }

  Future<Map<String, String>> _buildIndex() async {
    final text = <String, StringBuffer>{};
    final pages = <String, int>{};
    for (int page = 1; page <= 604; page++) {
      final raw = await rootBundle.loadString(_pagePath(page));
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final lines = (json['lines'] as List<dynamic>?) ?? const [];
      for (final l in lines) {
        final words = (l as Map?)?['words'] as List<dynamic>?;
        if (words == null) continue;
        for (final w in words) {
          final wMap = w as Map?;
          if (wMap == null) continue;
          final loc = wMap['location'] as String? ?? '';
          final word = wMap['word'] as String? ?? '';
          final parts = loc.split(':');
          if (parts.length < 2) continue;
          final key = '${parts[0]}:${parts[1]}';
          final buf = text.putIfAbsent(key, StringBuffer.new);
          if (buf.isNotEmpty) buf.write(' ');
          buf.write(word);
          // First page an ayah appears on — what search results jump to.
          pages.putIfAbsent(key, () => page);
        }
      }
    }
    final result = text.map((k, v) => MapEntry(k, v.toString()));
    _ayahTextIndex = result;
    _ayahNormalisedIndex = result.map((k, v) => MapEntry(k, _normalise(v)));
    _ayahPageIndex = pages;
    _buildingIndex = null;
    return result;
  }

  /// Strips Arabic diacritics and tatweel; collapses common alif variants.
  /// Used for tolerant matching — the query and the index pass through this
  /// same function so search is forgiving of fully/partially vocalised input.
  static String _normalise(String input) {
    final buf = StringBuffer();
    for (final code in input.runes) {
      // Skip Arabic diacritics: 0x064B..0x065F, 0x0670 (superscript alef),
      // 0x06D6..0x06ED (Quranic annotation signs), 0x0640 (tatweel).
      if ((code >= 0x064B && code <= 0x065F) ||
          code == 0x0670 ||
          (code >= 0x06D6 && code <= 0x06ED) ||
          code == 0x0640) {
        continue;
      }
      // Normalise alef variants → bare alef.
      if (code == 0x0623 || code == 0x0625 || code == 0x0622 || code == 0x0671) {
        buf.writeCharCode(0x0627);
        continue;
      }
      // ya / alef maqsura → ya.
      if (code == 0x0649) {
        buf.writeCharCode(0x064A);
        continue;
      }
      // ta marbuta → ha.
      if (code == 0x0629) {
        buf.writeCharCode(0x0647);
        continue;
      }
      buf.writeCharCode(code);
    }
    return buf.toString();
  }

  /// Public hook for cubits/use-cases that need to normalise a query string
  /// using the same rules as the index.
  static String normaliseForSearch(String input) => _normalise(input);

  /// Search the index for [normalisedQuery]. Caller must pass a string that
  /// has already been through [normaliseForSearch].
  Future<List<({ParamAyahRef ref, String snippet, int page})>> searchNormalised(String normalisedQuery, {int limit = 200}) async {
    if (normalisedQuery.isEmpty) return const [];
    await ayahTextIndex();
    final normIndex = _ayahNormalisedIndex ?? const {};
    final fullIndex = _ayahTextIndex ?? const {};
    final pageIndex = _ayahPageIndex ?? const {};
    final out = <({ParamAyahRef ref, String snippet, int page})>[];
    for (final entry in normIndex.entries) {
      final idx = entry.value.indexOf(normalisedQuery);
      if (idx < 0) continue;
      final parts = entry.key.split(':');
      final ref = ParamAyahRef(surah: int.parse(parts[0]), ayah: int.parse(parts[1]));
      out.add((ref: ref, snippet: fullIndex[entry.key] ?? '', page: pageIndex[entry.key] ?? 1));
      if (out.length >= limit) break;
    }
    return out;
  }
}
