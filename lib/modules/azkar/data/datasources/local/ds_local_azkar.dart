import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/azkar/data/models/m_azkar_catalog.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

class DSLocalAzkar {
  DSLocalAzkar();

  static const _dir = 'assets/data/azkar';
  static const _catalogFile = '$_dir/azkar_catigories.json';

  /// Prefix marking a category that came from `other_azkar.json`.
  static const otherPrefix = 'other_';

  List<MAzkarCatalog>? _catalogCache;
  List<MAzkarCategory>? _dailyCache;
  List<MAzkarCategory>? _otherCache;

  /// The category catalog from `azkar_catigories.json` (names, asset file, emoji).
  Future<List<MAzkarCatalog>> catalog() async {
    if (_catalogCache != null) return _catalogCache!;
    final raw = await rootBundle.loadString(_catalogFile);
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MAzkarCatalog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    _catalogCache = list;
    return list;
  }

  /// The daily azkar lists — every catalog row except the "other azkar" browser.
  Future<List<MAzkarCategory>> allCategories() async {
    if (_dailyCache != null) return _dailyCache!;
    final entries = (await catalog()).where((e) => !e.isOther);
    final list = <MAzkarCategory>[];
    for (final entry in entries) {
      final raw = await rootBundle.loadString('$_dir/${entry.filename}');
      final items = (jsonDecode(raw) as List<dynamic>)
          .map((e) => MAzkarItem.fromJson(Map<String, dynamic>.from(e as Map), entry.slug))
          .toList(growable: false);
      list.add(MAzkarCategory(
        id: entry.slug,
        nameAr: entry.nameAr,
        nameEn: entry.nameEn,
        items: items,
      ));
    }
    _dailyCache = list;
    return list;
  }

  /// Categories from `other_azkar.json` — a map of `{ category name: [items] }`.
  /// Each key becomes a category with a stable `other_<index>` id.
  Future<List<MAzkarCategory>> otherCategories() async {
    if (_otherCache != null) return _otherCache!;
    final raw = await rootBundle.loadString('$_dir/${MAzkarCatalog.otherFile}');
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final list = <MAzkarCategory>[];
    var index = 0;
    for (final entry in map.entries) {
      final id = '$otherPrefix$index';
      final items = (entry.value as List<dynamic>)
          .map((e) => MAzkarItem.fromJson(Map<String, dynamic>.from(e as Map), id))
          .toList(growable: false);
      list.add(MAzkarCategory(
        id: id,
        nameAr: entry.key,
        nameEn: entry.key,
        items: items,
      ));
      index++;
    }
    _otherCache = list;
    return list;
  }

  /// Resolves a category by id from either the daily set or `other_azkar.json`.
  Future<MAzkarCategory?> category(String id) async {
    final source = id.startsWith(otherPrefix)
        ? await otherCategories()
        : await allCategories();
    final hit = source.where((c) => c.id == id);
    return hit.isEmpty ? null : hit.first;
  }

  Future<MAzkarItem?> item(String itemId) async {
    final located = await locate(itemId);
    return located?.item;
  }

  /// Resolves a zekr together with its owning category and its position within
  /// that category, so a favorite can reopen the counter screen at the right
  /// zekr. Returns `null` if the id no longer exists in the bundled data.
  Future<({MAzkarItem item, MAzkarCategory category, int index})?> locate(
    String itemId,
  ) async {
    final all = [...await allCategories(), ...await otherCategories()];
    for (final cat in all) {
      final index = cat.items.indexWhere((it) => it.id == itemId);
      if (index >= 0) {
        return (item: cat.items[index], category: cat, index: index);
      }
    }
    return null;
  }
}
