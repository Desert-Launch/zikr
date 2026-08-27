import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_reciter.dart';

/// Loads the bundled reciter catalogue (`assets/data/reciters.json`).
///
/// Cached after the first read — the catalogue ships with the app and never
/// changes at runtime.
class DSLocalReciters {
  DSLocalReciters();

  static const String assetPath = 'assets/data/reciters.json';

  List<MReciter>? _cache;

  Future<List<MReciter>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(assetPath);
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MReciter.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    _cache = list;
    return list;
  }
}
