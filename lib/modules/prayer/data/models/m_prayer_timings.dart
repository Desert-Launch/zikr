/// Parsed prayer timings for a single day, decoded from the Aladhan
/// `/v1/timings` response `data` object.
///
/// Aladhan returns each timing as a local-clock string (e.g. `"04:13 (EEST)"`)
/// for the requested location's timezone. We attach those clock values to the
/// requested calendar [date] to produce concrete [DateTime]s. Optional minute
/// [offsets] (country adjustments) are folded in during parsing.
class MPrayerTimings {
  const MPrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.timezone = '',
    this.hijriDate = '',
    this.gregorianDate = '',
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String timezone;
  final String hijriDate;
  final String gregorianDate;

  /// [data] is the `data` node of the Aladhan response. [date] is the calendar
  /// day the timings belong to (the day we requested). [offsets] are optional
  /// per-prayer minute adjustments keyed by 'fajr'/'asr'/'maghrib'/'isha'.
  factory MPrayerTimings.fromJson(
    Map<String, dynamic> data, {
    required DateTime date,
    Map<String, int> offsets = const {},
  }) {
    final timings = (data['timings'] as Map?)?.cast<String, dynamic>() ?? {};
    final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    final dateNode = (data['date'] as Map?)?.cast<String, dynamic>() ?? {};
    final hijri = (dateNode['hijri'] as Map?)?.cast<String, dynamic>() ?? {};
    final greg = (dateNode['gregorian'] as Map?)?.cast<String, dynamic>() ?? {};

    DateTime at(String key, String offsetKey) => _parse(
          date,
          timings[key]?.toString() ?? '',
          offsets[offsetKey] ?? 0,
        );

    return MPrayerTimings(
      fajr: at('Fajr', 'fajr'),
      sunrise: at('Sunrise', 'sunrise'),
      dhuhr: at('Dhuhr', 'dhuhr'),
      asr: at('Asr', 'asr'),
      maghrib: at('Maghrib', 'maghrib'),
      isha: at('Isha', 'isha'),
      timezone: meta['timezone']?.toString() ?? '',
      hijriDate: hijri['date']?.toString() ?? '',
      gregorianDate: greg['date']?.toString() ?? '',
    );
  }

  /// Turns a raw timing string (`"04:13"` or `"04:13 (EEST)"`) into a concrete
  /// [DateTime] on [day], shifted by [offsetMinutes]. Falls back to midnight on
  /// [day] if the value can't be parsed.
  static DateTime _parse(DateTime day, String raw, int offsetMinutes) {
    final cleaned = raw.split('(').first.trim();
    final parts = cleaned.split(':');
    final h = parts.isNotEmpty ? int.tryParse(parts[0].trim()) ?? 0 : 0;
    final m = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, h, m)
        .add(Duration(minutes: offsetMinutes));
  }
}
