import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:quran/core/utils/helper/date_labels.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';

/// Every string the home-screen widget prints, already in the user's
/// language.
///
/// The widgets run without a Flutter engine, so they cannot call `.tr()`;
/// localisation happens here, once, and the natives only substitute the
/// prayer name and the countdown numbers into these templates.
class MPrayerWidgetLabels {
  const MPrayerWidgetLabels({
    required this.caption,
    required this.nextName,
    required this.after,
    required this.remainingHm,
    required this.remaining1Hm,
    required this.remainingM,
    required this.tomorrow,
    required this.empty,
    required this.prayers,
  });

  /// `الصلاة القادمة بتوقيت الدوحة` — the city is already substituted.
  final String caption;

  /// `صلاة {{name}}`.
  final String nextName;

  /// `بعد` — iOS prefixes it to the system-rendered relative countdown.
  final String after;

  /// `بعد {{h}} ساعة و {{m}} دقيقة` — Android renders the countdown itself.
  final String remainingHm;

  /// `بعد ساعة و {{m}} دقيقة` — the one-hour form, which Arabic words
  /// differently from "1 hours".
  final String remaining1Hm;

  /// `بعد {{m}} دقيقة`.
  final String remainingM;

  /// `الغد` — appended to the caption once the chip row rolls into tomorrow.
  final String tomorrow;

  /// Shown when the snapshot has nothing usable for the current moment.
  final String empty;

  /// Display name per slot, sunrise included.
  final Map<EPrayer, String> prayers;

  Map<String, dynamic> toJson() => {
    'caption': caption,
    'nextName': nextName,
    'after': after,
    'remainingHm': remainingHm,
    'remaining1Hm': remaining1Hm,
    'remainingM': remainingM,
    'tomorrow': tomorrow,
    'empty': empty,
    'prayers': {
      for (final prayer in EPrayer.values)
        prayer.key: prayers[prayer] ?? prayer.key,
    },
  };
}

/// What Dart hands the native home-screen widgets: a self-sufficient run of
/// days around today, as instants plus pre-formatted strings.
///
/// The widgets cannot run Dart, so they must be able to answer "what is the
/// next prayer and how long until it" from this alone, at any moment, for as
/// long as it is plausible the app has not run. Hence the window — yesterday
/// (so the pre-Fajr countdown starts from a real Isha) through a week ahead —
/// and hence the strings: the natives never localise, never format a time,
/// and never compute a Hijri date. They compare epoch millis against the
/// clock and pick rows.
///
/// The key is versioned. A widget built for `v1` keeps reading `v1` until an
/// app update ships a widget that understands whatever comes next; a shape
/// change must never crash a widget already on someone's home screen.
class MPrayerWidgetSnapshot {
  const MPrayerWidgetSnapshot({
    required this.lang,
    required this.timezone,
    required this.city,
    required this.generatedAt,
    required this.labels,
    required this.days,
  });

  /// Builds the window around [now] from [schedule].
  ///
  /// Missing days are skipped rather than faked, exactly like
  /// [EPrayerSchedule.window]; the natives walk whatever is there.
  factory MPrayerWidgetSnapshot.fromSchedule(
    EPrayerSchedule schedule, {
    required MPrayerWidgetLabels labels,
    required String lang,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final today = schedule.localDay(moment);
    final from = DateTime(today.year, today.month, today.day - 1);
    // Yesterday, today, and [windowDays] more.
    return MPrayerWidgetSnapshot(
      lang: lang,
      timezone: schedule.timezone,
      city: schedule.cityName,
      generatedAt: moment,
      labels: labels,
      days: schedule.window(from, windowDays + 2),
    );
  }

  static const int version = 1;

  /// The `home_widget` key both natives read.
  static const String storageKey = 'prayer_widget_v1';

  /// Where the digest of the last published snapshot lives, so a fresh
  /// process (the weekly background isolate, a cold start) can still tell an
  /// unchanged snapshot from a new one and spare the widget a reload.
  static const String hashKey = 'prayer_widget_v1_hash';

  /// Days ahead of today the window reaches. Yesterday is added on top.
  static const int windowDays = 7;

  final String lang;
  final String timezone;
  final String city;
  final DateTime generatedAt;
  final MPrayerWidgetLabels labels;
  final List<EDailyPrayerTimes> days;

  bool get isRtl => lang == 'ar';

  Map<String, dynamic> toJson() => {
    'v': version,
    'lang': lang,
    'rtl': isRtl,
    'tz': timezone,
    'city': city,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'labels': labels.toJson(),
    'days': [for (final day in days) _dayJson(day)],
  };

  String encode() => jsonEncode(toJson());

  /// Digest of everything the widget renders. `generatedAt` is deliberately
  /// left out: republishing an identical window must not count as a change,
  /// or every app open would cost an iOS timeline reload for nothing.
  String get contentHash {
    final json = toJson()..remove('generatedAt');
    return sha1.convert(utf8.encode(jsonEncode(json))).toString();
  }

  Map<String, dynamic> _dayJson(EDailyPrayerTimes day) => {
    'date': _isoDate(day.date),
    'gregorian': DateLabels.weekdayAndGregorian(day.date, lang: lang),
    'hijri': DateLabels.hijri(day.date, lang: lang),
    'slots': [
      for (final slot in day.slots)
        {
          'k': slot.prayer.key,
          'at': slot.time.millisecondsSinceEpoch,
          't': TimeFormat.h12Plain(slot.time),
        },
    ],
  };

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
