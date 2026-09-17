import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';

/// One month of prayer times for one location under one set of settings.
///
/// The month is the unit the app fetches and caches in, so opening the prayer
/// screen — or rebuilding a two-week notification window — normally costs no
/// network at all. Everything that could change the numbers travels with the
/// calendar ([latitude]/[longitude]/[settingsSignature]) so a cache read can
/// tell whether the entry still applies.
class EPrayerCalendar extends Equatable {
  const EPrayerCalendar({
    required this.year,
    required this.month,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.settingsSignature,
    required this.fetchedAt,
    required this.days,
    this.methodId,
    this.methodName,
    this.source = EPrayerSource.network,
  });

  final int year;
  final int month;

  /// Where it was fetched for. Compared against the user's current position to
  /// decide whether they have travelled far enough to need a refetch.
  final double latitude;
  final double longitude;

  /// IANA zone Aladhan resolved from the coordinates.
  final String timezone;

  /// [EPrayerSettings.cacheSignature] at fetch time.
  final String settingsSignature;

  final DateTime fetchedAt;

  /// The authority Aladhan actually used — in automatic mode, the one it
  /// picked. Stored so settings can show "Automatic · Umm Al-Qura".
  final int? methodId;
  final String? methodName;

  final List<EDailyPrayerTimes> days;

  final EPrayerSource source;

  /// The timings for [day]'s calendar date, or null when the month doesn't
  /// cover it.
  EDailyPrayerTimes? dayFor(DateTime day) {
    for (final entry in days) {
      if (entry.date.year == day.year &&
          entry.date.month == day.month &&
          entry.date.day == day.day) {
        return entry;
      }
    }
    return null;
  }

  bool covers(DateTime day) => day.year == year && day.month == month;

  EPrayerCalendar copyWith({EPrayerSource? source}) => EPrayerCalendar(
    year: year,
    month: month,
    latitude: latitude,
    longitude: longitude,
    timezone: timezone,
    settingsSignature: settingsSignature,
    fetchedAt: fetchedAt,
    days: days,
    methodId: methodId,
    methodName: methodName,
    source: source ?? this.source,
  );

  @override
  List<Object?> get props => [
    year,
    month,
    latitude,
    longitude,
    timezone,
    settingsSignature,
    fetchedAt,
    methodId,
    methodName,
    days,
    source,
  ];
}
