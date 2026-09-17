import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:timezone/timezone.dart' as tz;

/// The raw shape of one day in an Aladhan `/timings` or `/calendar` response,
/// kept separate from the domain entity it produces.
///
/// Its whole job is to survive the response rather than trust it: unknown
/// keys, missing optional timings, `-----` where a prayer does not occur at
/// polar latitudes, and clock strings that carry a zone abbreviation
/// (`"04:13 (EEST)"`) or do not.
class MAladhanDay {
  const MAladhanDay({
    required this.timings,
    required this.timezone,
    required this.date,
    this.methodId,
    this.methodName,
    this.hijriDate = '',
    this.gregorianDate = '',
  });

  /// Prayer name → clock string, exactly as the API sent it.
  final Map<String, String> timings;

  /// IANA zone from `meta.timezone`. Empty when the response omitted it.
  final String timezone;

  /// The calendar day these timings belong to.
  final DateTime date;

  final int? methodId;
  final String? methodName;
  final String hijriDate;
  final String gregorianDate;

  /// Reads one `data` node (a day). [fallbackDate] is used when the response
  /// carries no parsable Gregorian date — for `/timings/{date}` that is the
  /// date we asked for.
  ///
  /// Returns null rather than throwing when the node is not a day at all, so a
  /// single malformed entry cannot take a whole month's calendar down with it.
  static MAladhanDay? tryParse(Object? node, {DateTime? fallbackDate}) {
    if (node is! Map) return null;
    final data = node.cast<String, dynamic>();

    final rawTimings = data['timings'];
    if (rawTimings is! Map || rawTimings.isEmpty) return null;
    final timings = <String, String>{
      for (final entry in rawTimings.entries)
        entry.key.toString(): entry.value?.toString() ?? '',
    };

    final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final method = (meta['method'] as Map?)?.cast<String, dynamic>();
    final dateNode = (data['date'] as Map?)?.cast<String, dynamic>() ?? const {};
    final gregorian =
        (dateNode['gregorian'] as Map?)?.cast<String, dynamic>() ?? const {};
    final hijri = (dateNode['hijri'] as Map?)?.cast<String, dynamic>() ?? const {};

    final gregorianDate = gregorian['date']?.toString() ?? '';
    final date = _parseDayMonthYear(gregorianDate) ?? fallbackDate;
    if (date == null) return null;

    return MAladhanDay(
      timings: timings,
      timezone: meta['timezone']?.toString() ?? '',
      date: DateTime(date.year, date.month, date.day),
      methodId: (method?['id'] as num?)?.toInt(),
      methodName: method?['name']?.toString(),
      hijriDate: hijri['date']?.toString() ?? '',
      gregorianDate: gregorianDate,
    );
  }

  /// Materialises the clock strings as instants in the response's own IANA
  /// zone.
  ///
  /// Returns null when any of the six listed timings is missing or
  /// unparseable — at extreme latitudes Aladhan answers `-----` for a Fajr or
  /// Isha that does not occur, and a day that cannot say when Fajr is has
  /// nothing to offer. Callers skip it; the repository's on-device fallback
  /// still produces something for that day.
  EDailyPrayerTimes? toDomain() {
    final location = AppTimezone.resolve(timezone);

    // Walked in clock order so a value that lands earlier than the one before
    // it can be recognised as belonging to the following day — which is what
    // Isha at 00:12 in an Oslo summer, and Midnight/Lastthird everywhere,
    // actually are.
    tz.TZDateTime? previous;
    tz.TZDateTime? next(String key) {
      final clock = _parseClock(timings[key]);
      if (clock == null) return null;
      final resolved = _onDay(location, clock.$1, clock.$2, previous);
      previous = resolved;
      return resolved;
    }

    final imsak = next('Imsak');
    final fajr = next('Fajr');
    final sunrise = next('Sunrise');
    final dhuhr = next('Dhuhr');
    final asr = next('Asr');
    final sunset = next('Sunset');
    final maghrib = next('Maghrib');
    final isha = next('Isha');
    final firstThird = next('Firstthird');
    final midnight = next('Midnight');
    final lastThird = next('Lastthird');

    if (fajr == null ||
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
      imsak: imsak,
      sunset: sunset,
      midnight: midnight,
      firstThird: firstThird,
      lastThird: lastThird,
      timezone: timezone,
      calculationMethodId: methodId,
      calculationMethodName: methodName,
      hijriDate: hijriDate,
      gregorianDate: gregorianDate,
    );
  }

  /// Places `hour:minute` on [date] in [location], rolling to the next day when
  /// it lands well before [previous].
  ///
  /// The two-hour tolerance is the point: a genuine roll-over is a jump back of
  /// most of a day (Maghrib 22:44 → Isha 00:12), while a manual `tune` can put
  /// Maghrib a minute before Sunset without either of them changing date. A
  /// plain `isBefore` would push the tuned value 24 hours out.
  tz.TZDateTime _onDay(
    tz.Location location,
    int hour,
    int minute,
    tz.TZDateTime? previous,
  ) {
    final sameDay = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    if (previous == null ||
        !sameDay.isBefore(previous.subtract(const Duration(hours: 2)))) {
      return sameDay;
    }
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day + 1,
      hour,
      minute,
    );
  }

  /// `"04:13"` / `"04:13 (EEST)"` → (4, 13). Null for `-----`, an empty value,
  /// or anything else that is not a clock.
  static (int, int)? _parseClock(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.split('(').first.trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  /// `"05-09-2026"` → 5 September 2026. Null when the string is not that shape.
  static DateTime? _parseDayMonthYear(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
