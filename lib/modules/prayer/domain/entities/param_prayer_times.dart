/// Inputs the Aladhan timings request needs. [method] is the Aladhan numeric
/// calculation convention (resolved from the user's country); [school] maps
/// to madhab for Asr (0 = Shafi, 1 = Hanafi). [date] defaults to today when
/// omitted. [countryCode] (ISO-2) drives post-response adjustments (e.g. QA).
class ParamPrayerTimes {
  const ParamPrayerTimes({
    required this.latitude,
    required this.longitude,
    required this.method,
    this.school = 0,
    this.date,
    this.countryCode,
    this.cityLabel = '',
  });

  final double latitude;
  final double longitude;
  final int method;
  final int school;
  final DateTime? date;
  final String? countryCode;
  final String cityLabel;
}
