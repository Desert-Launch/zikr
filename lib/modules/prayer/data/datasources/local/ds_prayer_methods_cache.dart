import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';

/// Caches the `/v1/methods` list so the calculation-method picker opens
/// instantly and works offline.
///
/// The live endpoint stays the source of truth — this is a copy of the last
/// answer, refreshed whenever the picker is opened with a connection, never a
/// list the app maintains itself.
class DSPrayerMethodsCache {
  DSPrayerMethodsCache();

  static const String boxName = 'prayer_methods_cache';
  static const String _key = 'methods';
  static const String _fetchedAtKey = 'fetched_at';

  Box<String> get _box => Hive.box<String>(boxName);

  List<ECalculationMethod> read() {
    final raw = _box.get(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final node in list)
          if (node is Map)
            ECalculationMethod.fromJson(node.cast<String, dynamic>()),
      ];
    } catch (_) {
      return const []; // a corrupt entry is a miss, not an error
    }
  }

  DateTime? fetchedAt() {
    final raw = _box.get(_fetchedAtKey);
    final millis = int.tryParse(raw ?? '');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> write(List<ECalculationMethod> methods) async {
    await _box.put(
      _key,
      jsonEncode([for (final method in methods) method.toJson()]),
    );
    await _box.put(
      _fetchedAtKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
