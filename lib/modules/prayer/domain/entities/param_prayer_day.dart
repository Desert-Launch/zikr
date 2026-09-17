import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// Inputs for a single day's prayer times. Served from the month that contains
/// [date] wherever possible, so this rarely costs a request of its own.
class ParamPrayerDay {
  const ParamPrayerDay({
    required this.latitude,
    required this.longitude,
    required this.settings,
    this.date,
    this.countryCode,
  });

  final double latitude;
  final double longitude;
  final EPrayerSettings settings;

  /// Defaults to today when omitted.
  final DateTime? date;
  final String? countryCode;

  DateTime get day {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }
}
