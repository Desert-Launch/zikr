import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';

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
}
