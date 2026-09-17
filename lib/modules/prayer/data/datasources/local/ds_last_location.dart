import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';

/// Persists the last successful location fix (JSON in a `Box<String>`) so the
/// weekly background isolate — which can't acquire a fresh GPS fix — can still
/// compute prayer times, and so a foreground GPS failure can fall back to it.
///
/// The IANA timezone Aladhan resolved for that fix is stored alongside it.
/// That is what lets the app notice it has crossed into another zone even when
/// it has cached times in hand: a traveller with a valid cached month still
/// needs those times, and their notifications, rebuilt for where they now are.
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
        timezone: m['tz'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(LocationResult loc) async {
    // A fresh fix carries no timezone (only Aladhan can name it), so keep the
    // one already stored rather than dropping it — otherwise every GPS refresh
    // would erase the zone the travel check reads.
    final timezone = loc.timezone ?? read()?.timezone;
    await _box.put(
      _key,
      jsonEncode({
        'lat': loc.latitude,
        'lon': loc.longitude,
        'label': loc.label,
        'cc': loc.countryCode,
        'tz': timezone,
      }),
    );
  }

  /// Records the IANA zone the prayer API resolved for the stored coordinates.
  Future<void> writeTimezone(String timezone) async {
    final current = read();
    if (current == null || timezone.isEmpty) return;
    if (current.timezone == timezone) return;
    await _box.put(
      _key,
      jsonEncode({
        'lat': current.latitude,
        'lon': current.longitude,
        'label': current.label,
        'cc': current.countryCode,
        'tz': timezone,
      }),
    );
  }
}
