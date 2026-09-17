import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_next_prayer.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Loaded here rather than in setUpAll: the fixtures below are built while
  // the file is being collected, which happens before any setUp runs.
  AppTimezone.ensureInitialised();

  const resolver = UCGetNextPrayer();
  const zone = 'Africa/Cairo';
  final cairo = AppTimezone.resolve(zone);

  /// A day with the Cairo timings for 5 September 2026.
  EDailyPrayerTimes dayOn(int day, {int shiftMinutes = 0}) {
    tz.TZDateTime at(int hour, int minute) => tz.TZDateTime(
      cairo,
      2026,
      9,
      day,
      hour,
      minute,
    ).add(Duration(minutes: shiftMinutes));

    return EDailyPrayerTimes(
      date: DateTime(2026, 9, day),
      fajr: at(5, 5),
      sunrise: at(6, 34),
      dhuhr: at(12, 54),
      asr: at(16, 27),
      maghrib: at(19, 13),
      isha: at(20, 32),
      timezone: zone,
    );
  }

  tz.TZDateTime moment(int day, int hour, int minute) =>
      tz.TZDateTime(cairo, 2026, 9, day, hour, minute);

  final days = [dayOn(5), dayOn(6)];

  group('next prayer', () {
    test('before Fajr → Fajr', () {
      final next = resolver(days: days, now: moment(5, 3, 0));

      expect(next?.prayer, EPrayer.fajr);
      expect(next?.time, days.first.fajr);
    });

    test('between Fajr and Dhuhr → Dhuhr', () {
      expect(
        resolver(days: days, now: moment(5, 7, 0))?.prayer,
        EPrayer.dhuhr,
      );
    });

    test('between Dhuhr and Asr → Asr', () {
      expect(
        resolver(days: days, now: moment(5, 13, 30))?.prayer,
        EPrayer.asr,
      );
    });

    test('between Asr and Maghrib → Maghrib', () {
      expect(
        resolver(days: days, now: moment(5, 17, 0))?.prayer,
        EPrayer.maghrib,
      );
    });

    test('between Maghrib and Isha → Isha', () {
      expect(
        resolver(days: days, now: moment(5, 19, 30))?.prayer,
        EPrayer.isha,
      );
    });

    test("after Isha → tomorrow's Fajr, not today's", () {
      final next = resolver(days: days, now: moment(5, 21, 0));

      expect(next?.prayer, EPrayer.fajr);
      expect(next?.time, days[1].fajr);
      expect(next?.time.day, 6);
    });

    test('just after midnight → the same morning\'s Fajr', () {
      // The window that is open began with the previous evening's Isha, but
      // the next PRAYER is a few hours ahead on the current date.
      final next = resolver(days: days, now: moment(6, 0, 30));

      expect(next?.prayer, EPrayer.fajr);
      expect(next?.time.day, 6);
    });
  });

  group('sunrise', () {
    test('is never the next prayer, even in its own window', () {
      // 06:00 sits between Fajr (05:05) and sunrise (06:34).
      final next = resolver(days: days, now: moment(5, 6, 0));

      expect(next?.prayer, EPrayer.dhuhr);
      expect(next?.prayer, isNot(EPrayer.sunrise));
    });

    test('is never the current window either', () {
      final current = resolver.currentSalah(days: days, now: moment(5, 7, 0));

      expect(current?.prayer, EPrayer.fajr);
    });
  });

  group('current window', () {
    test('is the most recent salah', () {
      expect(
        resolver.currentSalah(days: days, now: moment(5, 17, 0))?.prayer,
        EPrayer.asr,
      );
    });

    test("before the first Fajr in the window it is the previous day's Isha", () {
      final withYesterday = [dayOn(4), ...days];
      final current = resolver.currentSalah(
        days: withYesterday,
        now: moment(5, 3, 0),
      );

      expect(current?.prayer, EPrayer.isha);
      expect(current?.time.day, 4);
    });

    test('is null when nothing precedes the moment', () {
      expect(
        resolver.currentSalah(days: days, now: moment(5, 0, 30)),
        isNull,
      );
    });

    test('a prayer exactly now counts as started, not upcoming', () {
      final now = days.first.dhuhr;

      expect(resolver.currentSalah(days: days, now: now)?.prayer, EPrayer.dhuhr);
      expect(resolver(days: days, now: now)?.prayer, EPrayer.asr);
    });
  });

  group('empty and exhausted input', () {
    test('no days → null', () {
      expect(resolver(days: const []), isNull);
      expect(resolver.currentSalah(days: const []), isNull);
    });

    test('a window entirely in the past → null', () {
      expect(resolver(days: days, now: moment(9, 0, 0)), isNull);
    });
  });

  group('countdown', () {
    test('is derived from the current time, never stored', () {
      final next = resolver(days: days, now: moment(5, 4, 5));

      expect(next?.remainingFrom(moment(5, 4, 5)), const Duration(hours: 1));
      // The same object gives a different answer a minute later — which is the
      // point of not persisting a Duration.
      expect(
        next?.remainingFrom(moment(5, 4, 6)),
        const Duration(minutes: 59),
      );
    });
  });

  group('DST', () {
    test('a spring-forward night does not skip or duplicate a prayer', () {
      // Europe/London springs forward at 01:00 on 29 March 2026: 01:00–02:00
      // does not exist. Fajr that morning is inside the hour that vanishes on
      // some conventions, so the sequence must stay strictly increasing.
      final london = AppTimezone.resolve('Europe/London');
      EDailyPrayerTimes day(int d, int fajrHour, int fajrMinute) =>
          EDailyPrayerTimes(
            date: DateTime(2026, 3, d),
            fajr: tz.TZDateTime(london, 2026, 3, d, fajrHour, fajrMinute),
            sunrise: tz.TZDateTime(london, 2026, 3, d, fajrHour + 2, 0),
            dhuhr: tz.TZDateTime(london, 2026, 3, d, 12, 5),
            asr: tz.TZDateTime(london, 2026, 3, d, 15, 30),
            maghrib: tz.TZDateTime(london, 2026, 3, d, 18, 20),
            isha: tz.TZDateTime(london, 2026, 3, d, 19, 55),
            timezone: 'Europe/London',
          );

      final window = [day(28, 4, 30), day(29, 5, 20), day(30, 5, 15)];
      final salah = [
        for (final d in window) ...d.salahSlots.map((s) => s.time),
      ];

      for (var i = 1; i < salah.length; i++) {
        expect(
          salah[i].isAfter(salah[i - 1]),
          isTrue,
          reason: '${salah[i]} must follow ${salah[i - 1]}',
        );
      }

      final next = resolver(
        days: window,
        now: tz.TZDateTime(london, 2026, 3, 29, 0, 30),
      );
      expect(next?.prayer, EPrayer.fajr);
      expect(next?.time.day, 29);
    });
  });
}
