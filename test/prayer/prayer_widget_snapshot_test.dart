import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_widget_snapshot.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  AppTimezone.ensureInitialised();

  const zone = 'Asia/Qatar';
  final doha = AppTimezone.resolve(zone);

  /// Doha timings (the mock's numbers) on [date].
  EDailyPrayerTimes dayOn(DateTime date) {
    tz.TZDateTime at(int hour, int minute) =>
        tz.TZDateTime(doha, date.year, date.month, date.day, hour, minute);
    return EDailyPrayerTimes(
      date: date,
      fajr: at(5, 15),
      sunrise: at(6, 45),
      dhuhr: at(12, 30),
      asr: at(15, 45),
      maghrib: at(18, 15),
      isha: at(19, 45),
      timezone: zone,
    );
  }

  const labels = MPrayerWidgetLabels(
    caption: 'الصلاة القادمة بتوقيت الدوحة',
    nextName: 'صلاة {{name}}',
    after: 'بعد',
    remainingHm: 'بعد {{h}} ساعة و {{m}} دقيقة',
    remaining1Hm: 'بعد ساعة و {{m}} دقيقة',
    remainingM: 'بعد {{m}} دقيقة',
    tomorrow: 'الغد',
    empty: 'افتح التطبيق',
    prayers: {
      EPrayer.fajr: 'الفجر',
      EPrayer.sunrise: 'الشروق',
      EPrayer.dhuhr: 'الظهر',
      EPrayer.asr: 'العصر',
      EPrayer.maghrib: 'المغرب',
      EPrayer.isha: 'العشاء',
    },
  );

  EPrayerSchedule schedule({List<EDailyPrayerTimes>? days}) => EPrayerSchedule(
    latitude: 25.28,
    longitude: 51.53,
    cityName: 'الدوحة',
    timezone: zone,
    // 20 Aug – 10 Sep unless told otherwise.
    days: days ?? [for (var d = 0; d < 22; d++) dayOn(DateTime(2026, 8, 20 + d))],
    source: EPrayerSource.network,
    fetchedAt: DateTime(2026, 8, 29),
  );

  final now = tz.TZDateTime(doha, 2026, 8, 29, 11, 15);

  group('MPrayerWidgetSnapshot', () {
    test('window is yesterday through a week ahead, in order', () {
      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: now,
      );

      // Yesterday + today + 7 more.
      expect(snapshot.days.length, MPrayerWidgetSnapshot.windowDays + 2);
      expect(snapshot.days.first.date, DateTime(2026, 8, 28));
      expect(snapshot.days[1].date, DateTime(2026, 8, 29));
      expect(snapshot.days.last.date, DateTime(2026, 9, 5));
    });

    test('window is trimmed to the days the schedule actually has', () {
      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule(days: [for (var d = 25; d <= 31; d++) dayOn(DateTime(2026, 8, d))]),
        labels: labels,
        lang: 'ar',
        now: now,
      );

      // 28 Aug (yesterday) … 31 Aug: the fixture has nothing past the 31st and
      // nothing is faked to fill the gap.
      expect(
        snapshot.days.map((d) => d.date.day).toList(),
        [28, 29, 30, 31],
      );
    });

    test('json carries the versioned shape both natives read', () {
      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: now,
      );
      final json = jsonDecode(snapshot.encode()) as Map<String, dynamic>;

      expect(json['v'], 1);
      expect(json['lang'], 'ar');
      expect(json['rtl'], isTrue);
      expect(json['tz'], zone);
      expect(json['city'], 'الدوحة');
      expect(json['generatedAt'], now.millisecondsSinceEpoch);

      final labelsJson = json['labels'] as Map<String, dynamic>;
      expect(labelsJson['caption'], 'الصلاة القادمة بتوقيت الدوحة');
      expect(labelsJson['remaining1Hm'], 'بعد ساعة و {{m}} دقيقة');
      expect((labelsJson['prayers'] as Map)['dhuhr'], 'الظهر');

      final days = json['days'] as List;
      final today = days[1] as Map<String, dynamic>;
      expect(today['date'], '2026-08-29');
      expect(today['gregorian'], 'السبت، 29 أغسطس 2026');
      expect(today['hijri'], '15 ربيع الأول 1448 هـ');

      final slots = today['slots'] as List;
      expect(slots.length, 6);
      expect(
        slots.map((s) => (s as Map)['k']).toList(),
        ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'],
      );
      final dhuhr = slots[2] as Map<String, dynamic>;
      expect(dhuhr['at'], tz.TZDateTime(doha, 2026, 8, 29, 12, 30).millisecondsSinceEpoch);
      expect(dhuhr['t'], '12:30');
      expect((slots[0] as Map)['t'], '5:15');
      expect((slots[5] as Map)['t'], '7:45');
    });

    test('english snapshot is LTR with english date labels', () {
      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'en',
        now: now,
      );
      final json = jsonDecode(snapshot.encode()) as Map<String, dynamic>;
      expect(json['rtl'], isFalse);
      final today = (json['days'] as List)[1] as Map<String, dynamic>;
      expect(today['gregorian'], 'Saturday, 29 August 2026');
      expect(today['hijri'], '15 Rabi al-Awwal 1448 AH');
    });

    test('content hash ignores generatedAt but tracks the window', () {
      final a = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: now,
      );
      final b = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: now.add(const Duration(hours: 3)),
      );
      final c = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: now.add(const Duration(days: 1)),
      );

      expect(a.contentHash, b.contentHash, reason: 'same day, later hour');
      expect(a.contentHash, isNot(c.contentHash), reason: 'window slid a day');
    });

    test('today is picked in the location zone, not the device zone', () {
      // 23:30 in New York on the 28th is already 06:30 on the 29th in Doha.
      final newYork = AppTimezone.resolve('America/New_York');
      final lateNight = tz.TZDateTime(newYork, 2026, 8, 28, 23, 30);

      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule(),
        labels: labels,
        lang: 'ar',
        now: lateNight,
      );

      expect(snapshot.days.first.date, DateTime(2026, 8, 28), reason: 'yesterday');
      expect(snapshot.days[1].date, DateTime(2026, 8, 29), reason: 'today in Doha');
    });
  });
}
