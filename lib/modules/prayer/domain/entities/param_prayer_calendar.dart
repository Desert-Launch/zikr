import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// Inputs for one month of prayer times.
///
/// Coordinates are the primary input — no city lookup is required, and
/// [countryCode] is carried only for logging and the offline calculation
/// fallback, never to choose a calculation method.
class ParamPrayerCalendar {
  const ParamPrayerCalendar({
    required this.latitude,
    required this.longitude,
    required this.year,
    required this.month,
    required this.settings,
    this.countryCode,
    this.forceRefresh = false,
    this.cacheOnly = false,
  });

  final double latitude;
  final double longitude;
  final int year;
  final int month;
  final EPrayerSettings settings;
  final String? countryCode;

  /// Skips the "cache is still fresh" shortcut — a pull-to-refresh, or a
  /// settings change that has already invalidated the entry.
  final bool forceRefresh;

  /// Answer from what is already stored, or not at all.
  ///
  /// This is the first-paint path: the screen wants something on it now, and a
  /// network round trip there would both delay the paint and race the live
  /// refresh that follows a second later. It stops short of on-device
  /// calculation too — approximate times that are replaced the moment the real
  /// ones land read as a glitch.
  final bool cacheOnly;

  ParamPrayerCalendar forMonth(int year, int month) => ParamPrayerCalendar(
    latitude: latitude,
    longitude: longitude,
    year: year,
    month: month,
    settings: settings,
    countryCode: countryCode,
    forceRefresh: forceRefresh,
    cacheOnly: cacheOnly,
  );
}
