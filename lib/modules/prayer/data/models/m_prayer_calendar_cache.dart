import 'dart:convert';

import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// JSON codec for a cached [EPrayerCalendar].
///
/// Entries are stored as strings in a plain `Box<String>` — no Hive adapter,
/// no typeId, nothing for a schema change to break, and readable in a log when
/// a month looks wrong.
///
/// Each timing is written as its **wall clock in the month's own timezone**
/// (`2026-10-25 04:49`) rather than as an epoch. Both round-trip today, but a
/// clock value is re-resolved against the current tz database on read — so
/// when a country changes its DST rules mid-cache, the cached month follows
/// the new rules instead of firing an hour out until it is refetched. It also
/// preserves the day a value belongs to, which matters for an Isha that falls
/// after midnight at high latitude.
class MPrayerCalendarCache {
  MPrayerCalendarCache._();

  /// Cache key for a month under a given set of settings.
  ///
  /// The settings signature is part of the key, so changing the method, the
  /// Asr school, the high-latitude rule or a tune value lands on a different
  /// entry instead of reading back times computed under the old ones. The
  /// location is NOT in the key — it is stored in the record and checked by
  /// distance, because "did the user travel far enough to matter" is a
  /// threshold question, not an equality one.
  static String keyFor({
    required int year,
    required int month,
    required String settingsSignature,
  }) => '$year-$month#$settingsSignature';

  static String encode(EPrayerCalendar calendar) => jsonEncode({
    'y': calendar.year,
    'mo': calendar.month,
    'lat': calendar.latitude,
    'lon': calendar.longitude,
    'tz': calendar.timezone,
    'sig': calendar.settingsSignature,
    'at': calendar.fetchedAt.millisecondsSinceEpoch,
    'mid': calendar.methodId,
    'mname': calendar.methodName,
    'days': [for (final day in calendar.days) _encodeDay(day)],
  });

  /// Returns null for a missing, truncated or otherwise unreadable entry — a
  /// corrupt record is treated as a cache miss, never as an error.
  static EPrayerCalendar? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final timezone = map['tz']?.toString() ?? '';
      final location = AppTimezone.resolve(timezone);
      final days = <EDailyPrayerTimes>[
        for (final node in (map['days'] as List? ?? const []))
          if (node is Map)
            if (_decodeDay(node.cast<String, dynamic>(), location, timezone)
                case final day?)
              day,
      ];
      if (days.isEmpty) return null;

      return EPrayerCalendar(
        year: (map['y'] as num).toInt(),
        month: (map['mo'] as num).toInt(),
        latitude: (map['lat'] as num).toDouble(),
        longitude: (map['lon'] as num).toDouble(),
        timezone: timezone,
        settingsSignature: map['sig']?.toString() ?? '',
        fetchedAt: DateTime.fromMillisecondsSinceEpoch((map['at'] as num).toInt()),
        methodId: (map['mid'] as num?)?.toInt(),
        methodName: map['mname']?.toString(),
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _encodeDay(EDailyPrayerTimes day) => {
    'd': _formatDate(day.date),
    'fajr': _formatStamp(day.fajr),
    'sunrise': _formatStamp(day.sunrise),
    'dhuhr': _formatStamp(day.dhuhr),
    'asr': _formatStamp(day.asr),
    'maghrib': _formatStamp(day.maghrib),
    'isha': _formatStamp(day.isha),
    if (day.imsak != null) 'imsak': _formatStamp(day.imsak),
    if (day.sunset != null) 'sunset': _formatStamp(day.sunset),
    if (day.midnight != null) 'midnight': _formatStamp(day.midnight),
    if (day.firstThird != null) 'first3': _formatStamp(day.firstThird),
    if (day.lastThird != null) 'last3': _formatStamp(day.lastThird),
    'mid': day.calculationMethodId,
    'mname': day.calculationMethodName,
    'hijri': day.hijriDate,
    'greg': day.gregorianDate,
  };

  static EDailyPrayerTimes? _decodeDay(
    Map<String, dynamic> node,
    tz.Location location,
    String timezone,
  ) {
    final date = _parseDate(node['d']?.toString());
    tz.TZDateTime? at(String key) =>
        _parseStamp(node[key]?.toString(), location);

    final fajr = at('fajr');
    final sunrise = at('sunrise');
    final dhuhr = at('dhuhr');
    final asr = at('asr');
    final maghrib = at('maghrib');
    final isha = at('isha');
    if (date == null ||
        fajr == null ||
        sunrise == null ||
        dhuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    return EDailyPrayerTimes(
      date: date,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      imsak: at('imsak'),
      sunset: at('sunset'),
      midnight: at('midnight'),
      firstThird: at('first3'),
      lastThird: at('last3'),
      timezone: timezone,
      calculationMethodId: (node['mid'] as num?)?.toInt(),
      calculationMethodName: node['mname']?.toString(),
      hijriDate: node['hijri']?.toString() ?? '',
      gregorianDate: node['greg']?.toString() ?? '',
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _formatDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String? _formatStamp(DateTime? value) => value == null
      ? null
      : '${_formatDate(value)} ${_two(value.hour)}:${_two(value.minute)}';

  static DateTime? _parseDate(String? raw) {
    final parts = raw?.split('-');
    if (parts == null || parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static tz.TZDateTime? _parseStamp(String? raw, tz.Location location) {
    if (raw == null) return null;
    final halves = raw.split(' ');
    if (halves.length != 2) return null;
    final date = _parseDate(halves[0]);
    final clock = halves[1].split(':');
    if (date == null || clock.length < 2) return null;
    final hour = int.tryParse(clock[0]);
    final minute = int.tryParse(clock[1]);
    if (hour == null || minute == null) return null;
    return tz.TZDateTime(location, date.year, date.month, date.day, hour, minute);
  }
}
