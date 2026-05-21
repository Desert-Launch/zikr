import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Loads bundled Quran assets from `assets/data/`.
class DSLocalQuran {
  DSLocalQuran();

  static const _surahsPath = 'assets/data/surahs.json';
  static String _pagePath(int page) =>
      'assets/data/mushaf_pages/page-${page.toString().padLeft(3, '0')}.json';

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

  /// Find which page contains (surah, ayah). Falls back to surah.pageStart.
  Future<int> pageOfAyah(int surah, int ayah) async {
    final surahs = await loadSurahs();
    final s = surahs.firstWhere(
      (e) => e.number == surah,
      orElse: () => surahs.first,
    );
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

  /// Plain Uthmani text per ayah, keyed by `"surah:ayah"`. Built once by
  /// streaming through all 604 page JSONs and aggregating words; cached
  /// for the rest of the session.
  Map<String, String>? _ayahTextIndex;
  Map<String, String>? _ayahNormalisedIndex;
  Future<Map<String, String>>? _buildingIndex;

  /// Returns the full ayah-text index, building it lazily on first call.
  Future<Map<String, String>> ayahTextIndex() {
    final existing = _ayahTextIndex;
    if (existing != null) return Future.value(existing);
    return _buildingIndex ??= _buildIndex();
  }

  Future<Map<String, String>> _buildIndex() async {
    final text = <String, StringBuffer>{};
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
        }
      }
    }
    final result = text.map((k, v) => MapEntry(k, v.toString()));
    _ayahTextIndex = result;
    _ayahNormalisedIndex = result.map((k, v) => MapEntry(k, _normalise(v)));
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
  Future<List<({ParamAyahRef ref, String snippet})>> searchNormalised(
    String normalisedQuery, {
    int limit = 200,
  }) async {
    if (normalisedQuery.isEmpty) return const [];
    await ayahTextIndex();
    final normIndex = _ayahNormalisedIndex ?? const {};
    final fullIndex = _ayahTextIndex ?? const {};
    final out = <({ParamAyahRef ref, String snippet})>[];
    for (final entry in normIndex.entries) {
      final idx = entry.value.indexOf(normalisedQuery);
      if (idx < 0) continue;
      final parts = entry.key.split(':');
      final ref = ParamAyahRef(
        surah: int.parse(parts[0]),
        ayah: int.parse(parts[1]),
      );
      out.add((ref: ref, snippet: fullIndex[entry.key] ?? ''));
      if (out.length >= limit) break;
    }
    return out;
  }
}
