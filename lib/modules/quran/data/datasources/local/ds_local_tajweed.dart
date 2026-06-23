import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_tajweed_token.dart';

/// Loads the pre-computed Tajweed token dataset from `assets/data/tajweed/`.
///
/// Each `page-NNN.json` maps `"surah:ayah"` → ordered token list, for exactly
/// the ayahs that *begin* on QPC page NNN (built offline from cpfair — see
/// `docs/plans/Tajweed_Approach_B_Plan.md` §3). There is zero parsing of rule
/// offsets at runtime; spans are reconstructed directly from the substrings.
class DSLocalTajweed {
  DSLocalTajweed();

  static String _pagePath(int page) =>
      'assets/data/tajweed/page-${page.toString().padLeft(3, '0')}.json';

  // Cap the cache like the other page loaders — keep the last 12 visited.
  final Map<int, Map<String, List<MTajweedToken>>> _cache = {};

  /// Tokens for every ayah beginning on [page], keyed by `"surah:ayah"`.
  Future<Map<String, List<MTajweedToken>>> loadPage(int page) async {
    final cached = _cache[page];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_pagePath(page));
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final out = <String, List<MTajweedToken>>{};
    for (final entry in json.entries) {
      out[entry.key] = (entry.value as List<dynamic>)
          .map((e) => MTajweedToken.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }
    _cache[page] = out;
    if (_cache.length > 12) {
      _cache.remove(_cache.keys.first);
    }
    return out;
  }
}
