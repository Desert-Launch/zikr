import 'package:equatable/equatable.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:timezone/timezone.dart' as tz;

/// Everything the app needs to show prayer times and schedule adhan for one
/// place: where, in which zone, under which authority, and the run of days
/// around today.
///
/// It spans month boundaries deliberately — the prayer screen has to roll into
/// tomorrow after Isha, and the notification window reaches a fortnight ahead,
/// so neither can be handed a single month and left to cope.
class EPrayerSchedule extends Equatable {
  const EPrayerSchedule({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.days,
    required this.source,
    required this.fetchedAt,
    this.cityName = '',
    this.countryCode,
    this.methodId,
    this.methodName,
    this.mode = ECalculationMode.automatic,
  });

  final double latitude;
  final double longitude;

  /// Display only — prayer times never depend on reverse geocoding.
  final String cityName;
  final String? countryCode;

  /// IANA zone Aladhan resolved for these coordinates.
  final String timezone;

  /// Ordered from the day before today to the end of the covered window.
  ///
  /// Yesterday is included on purpose: before today's Fajr, the window the
  /// user is inside began with last night's Isha, and anchoring a countdown
  /// there is only honest if that Isha is a real timing rather than today's
  /// shifted back by a day.
  final List<EDailyPrayerTimes> days;

  final EPrayerSource source;
  final DateTime fetchedAt;

  /// The authority the times were actually calculated with — in automatic
  /// mode, the one Aladhan chose.
  final int? methodId;
  final String? methodName;

  final ECalculationMode mode;

  bool get isEmpty => days.isEmpty;

  /// Today's date **in the location's zone**, which is not always the device's.
  /// A traveller whose phone has not caught up must still see the right day's
  /// prayers.
  DateTime localDay([DateTime? now]) {
    final moment = tz.TZDateTime.from(
      now ?? DateTime.now(),
      AppTimezone.resolve(timezone),
    );
    return DateTime(moment.year, moment.month, moment.day);
  }

  EDailyPrayerTimes? today([DateTime? now]) => dayFor(localDay(now));

  EDailyPrayerTimes? tomorrow([DateTime? now]) {
    final day = localDay(now);
    return dayFor(DateTime(day.year, day.month, day.day + 1));
  }

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

  /// [count] consecutive days starting at [from] (missing days are skipped
  /// rather than faked).
  List<EDailyPrayerTimes> window(DateTime from, int count) => [
    for (var offset = 0; offset < count; offset++)
      if (dayFor(DateTime(from.year, from.month, from.day + offset))
          case final day?)
        day,
  ];

  /// Today onwards — what the next-prayer resolver walks.
  List<EDailyPrayerTimes> fromToday([DateTime? now]) {
    final day = localDay(now);
    return days
        .where((entry) => !entry.date.isBefore(day))
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    cityName,
    countryCode,
    timezone,
    days,
    source,
    fetchedAt,
    methodId,
    methodName,
    mode,
  ];
}
