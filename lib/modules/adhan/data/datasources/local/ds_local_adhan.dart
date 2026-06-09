import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/adhan/data/models/m_adhan.dart';

class DSLocalAdhan {
  DSLocalAdhan();

  List<MAdhan>? _cache;

  Future<List<MAdhan>> all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/adhans.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MAdhan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    _cache = list;
    return list;
  }

  /// Locale-aware default. Egyptian Arabic → Sheikh Rifat;
  /// other Arabic locales → Makkah; non-Arabic → Alafasy.
  Future<MAdhan> defaultForLocale(String localeTag) async {
    final list = await all();
    final hit = list.firstWhere(
      (a) => a.defaultForLocales.contains(localeTag),
      orElse: () {
        if (localeTag.startsWith('ar')) {
          return list.firstWhere((a) => a.id == 'adhan_mecca',
              orElse: () => list.first);
        }
        return list.firstWhere((a) => a.id == 'adhan_aaqib',
            orElse: () => list.first);
      },
    );
    return hit;
  }

  Future<MAdhan> fajrDefault() async {
    final list = await all();
    return list.firstWhere((a) => a.isFajrDefault, orElse: () => list.first);
  }

  Future<MAdhan?> byId(String id) async {
    final list = await all();
    final hits = list.where((a) => a.id == id);
    return hits.isEmpty ? null : hits.first;
  }
}
