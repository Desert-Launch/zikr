import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

class DSLocalAzkar {
  DSLocalAzkar();

  static const _categoryIds = [
    'morning',
    'evening',
    'after_prayer',
    'sleep',
    'general',
  ];

  List<MAzkarCategory>? _cache;

  Future<List<MAzkarCategory>> allCategories() async {
    if (_cache != null) return _cache!;
    final list = <MAzkarCategory>[];
    for (final id in _categoryIds) {
      final raw = await rootBundle.loadString('assets/data/azkar/$id.json');
      list.add(MAzkarCategory.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      ));
    }
    _cache = list;
    return list;
  }

  Future<MAzkarCategory?> category(String id) async {
    final all = await allCategories();
    final hit = all.where((c) => c.id == id);
    return hit.isEmpty ? null : hit.first;
  }

  Future<MAzkarItem?> item(String itemId) async {
    final all = await allCategories();
    for (final cat in all) {
      for (final it in cat.items) {
        if (it.id == itemId) return it;
      }
    }
    return null;
  }
}
