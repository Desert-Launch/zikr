import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:timezone/timezone.dart' as tz;

/// One day's prayer moments, as instants rather than clock strings.
///
/// Every field is a [tz.TZDateTime] in the *location's* IANA zone, not the
/// device's. That is the whole point: the wall clock reads what a mosque at
/// those coordinates would announce, and the underlying instant is what a
/// notification has to be scheduled at — the two stay consistent through a DST
/// change, a flight, and a device whose zone hasn't caught up yet.
///
/// The optional fields are optional because Aladhan may omit them; a missing
/// one must never take the five obligatory prayers down with it.
class EDailyPrayerTimes extends Equatable {
  const EDailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.timezone,
    this.imsak,
    this.sunset,
    this.midnight,
    this.firstThird,
    this.lastThird,
    this.calculationMethodId,
    this.calculationMethodName,
    this.hijriDate = '',
    this.gregorianDate = '',
  });

  /// The calendar day these timings belong to, in the location's zone (time
  /// component is midnight, and it is only ever used as a date).
  final DateTime date;

  final tz.TZDateTime fajr;
  final tz.TZDateTime sunrise;
  final tz.TZDateTime dhuhr;
  final tz.TZDateTime asr;
  final tz.TZDateTime maghrib;
  final tz.TZDateTime isha;

  final tz.TZDateTime? imsak;
  final tz.TZDateTime? sunset;
  final tz.TZDateTime? midnight;
  final tz.TZDateTime? firstThird;
  final tz.TZDateTime? lastThird;

  /// IANA zone the times above are expressed in, e.g. `Africa/Cairo`.
  final String timezone;

  /// What Aladhan actually calculated with — in automatic mode this is the
  /// authority it chose, which is the only way the UI can name it.
  final int? calculationMethodId;
  final String? calculationMethodName;

  final String hijriDate;
  final String gregorianDate;

  /// The moment of [prayer], sunrise included (it is listed, though it is not
  /// a salah — see [EPrayerX.isSalah]).
  tz.TZDateTime timeFor(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => fajr,
    EPrayer.sunrise => sunrise,
    EPrayer.dhuhr => dhuhr,
    EPrayer.asr => asr,
    EPrayer.maghrib => maghrib,
    EPrayer.isha => isha,
  };

  /// The six rows the prayer screen lists, in clock order.
  List<PrayerSlot> get slots => [
    for (final prayer in EPrayer.values)
      PrayerSlot(prayer: prayer, time: timeFor(prayer)),
  ];

  /// Only the five obligatory prayers — what notifications and next-prayer
  /// logic work from.
  List<PrayerSlot> get salahSlots =>
      slots.where((s) => s.prayer.isSalah).toList(growable: false);

  @override
  List<Object?> get props => [
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    imsak,
    sunset,
    midnight,
    firstThird,
    lastThird,
    timezone,
    calculationMethodId,
    calculationMethodName,
  ];
}
