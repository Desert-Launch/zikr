import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';

/// Persists the last successful location fix (JSON in a `Box<String>`) so the
/// weekly background isolate — which can't acquire a fresh GPS fix — can still
/// compute prayer times, and so a foreground GPS failure can fall back to it.
class DSLastLocation {
  DSLastLocation();

  static const String boxName = 'last_location';
  static const String _key = 'loc';

  Box<String> get _box => Hive.box<String>(boxName);

  LocationResult? read() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return LocationResult(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lon'] as num).toDouble(),
        label: m['label'] as String? ?? '',
        countryCode: m['cc'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(LocationResult loc) async {
    await _box.put(
      _key,
      jsonEncode({
        'lat': loc.latitude,
        'lon': loc.longitude,
        'label': loc.label,
        'cc': loc.countryCode,
      }),
    );
  }
}
