import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';

/// Hive-backed cache of computed prayer timings — one entry per
/// day+location+method, stored as JSON in a `Box<String>` (a built-in Hive
/// type, so no adapter/codegen). Lets the scheduler — including the weekly
/// background isolate — reschedule for days already fetched without hitting
/// the network again, and degrade gracefully offline.
class DSPrayerCache {
  DSPrayerCache();

  static const String boxName = 'prayer_timings_cache';

  Box<String> get _box => Hive.box<String>(boxName);

  /// Returns the cached timings for [key], or null on a miss / corrupt entry.
  MPrayerTimings? read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      DateTime at(String k) => DateTime.fromMillisecondsSinceEpoch(m[k] as int);
      return MPrayerTimings(
        fajr: at('fajr'),
        sunrise: at('sunrise'),
        dhuhr: at('dhuhr'),
        asr: at('asr'),
        maghrib: at('maghrib'),
        isha: at('isha'),
        timezone: m['tz'] as String? ?? '',
        hijriDate: m['hijri'] as String? ?? '',
        gregorianDate: m['greg'] as String? ?? '',
      );
    } catch (_) {
      return null; // treat a corrupt entry as a miss
    }
  }

  /// Persists [timings] under [key] (absolute instants, so they survive a
  /// timezone change), then prunes past days.
  Future<void> write(String key, MPrayerTimings timings) async {
    final payload = jsonEncode({
      'fajr': timings.fajr.millisecondsSinceEpoch,
      'sunrise': timings.sunrise.millisecondsSinceEpoch,
      'dhuhr': timings.dhuhr.millisecondsSinceEpoch,
      'asr': timings.asr.millisecondsSinceEpoch,
      'maghrib': timings.maghrib.millisecondsSinceEpoch,
      'isha': timings.isha.millisecondsSinceEpoch,
      'tz': timings.timezone,
      'hijri': timings.hijriDate,
      'greg': timings.gregorianDate,
    });
    await _box.put(key, payload);
    await _pruneStale();
  }

  /// Drops entries whose day (the `yyyy-M-d` key prefix) is before today, so
  /// the box stays bounded to the current/upcoming window.
  Future<void> _pruneStale() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stale = <dynamic>[];
    for (final key in _box.keys) {
      final date = _dateFromKey(key.toString());
      if (date != null && date.isBefore(today)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  DateTime? _dateFromKey(String key) {
    final parts = key.split('_').first.split('-'); // yyyy-M-d
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
