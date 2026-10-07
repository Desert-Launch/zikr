import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/notifications/hourly_rotation.dart';
import 'package:quran/core/services/notifications/notification_window.dart';

void main() {
  /// Zekr numbers (1-based) a rotation hands out on [day].
  List<int> dayOf(HourlyRotation rotation, int day) => [
    for (var slot = 0; slot < rotation.slotsPerDay; slot++)
      rotation.rowFor(day: day, slot: slot) + 1,
  ];

  group('HourlyRotation.rowFor', () {
    test('5 hours, 10 azkar: first five, then the other five, and so on', () {
      const rotation = HourlyRotation(slotsPerDay: 5, zikrCount: 10);
      expect(rotation.fitsInOneDay, isFalse);
      expect(dayOf(rotation, 0), [1, 2, 3, 4, 5]);
      expect(dayOf(rotation, 1), [6, 7, 8, 9, 10]);
      expect(dayOf(rotation, 2), [1, 2, 3, 4, 5]);
      expect(dayOf(rotation, 3), [6, 7, 8, 9, 10]);
      expect(rotation.daysToCoverAll, 2);
    });

    test('5 hours, 12 azkar: each day continues where the last stopped', () {
      const rotation = HourlyRotation(slotsPerDay: 5, zikrCount: 12);
      expect(dayOf(rotation, 0), [1, 2, 3, 4, 5]);
      expect(dayOf(rotation, 1), [6, 7, 8, 9, 10]);
      expect(dayOf(rotation, 2), [11, 12, 1, 2, 3]);
      expect(dayOf(rotation, 3), [4, 5, 6, 7, 8]);
      expect(rotation.daysToCoverAll, 3);
    });

    test('a day before the anchor still lands on a valid zekr', () {
      const rotation = HourlyRotation(slotsPerDay: 5, zikrCount: 12);
      // Day -1 is the cycle's tail: the five azkar that lead into day 0.
      expect(dayOf(rotation, -1), [8, 9, 10, 11, 12]);
    });

    test('a range that holds every zekr repeats the same day', () {
      const rotation = HourlyRotation(slotsPerDay: 15, zikrCount: 12);
      expect(rotation.fitsInOneDay, isTrue);
      expect(rotation.daysToCoverAll, 1);
      final expected = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3];
      expect(dayOf(rotation, 0), expected);
      expect(dayOf(rotation, 7), expected);
    });

    test('exactly as many hours as azkar fits in one day', () {
      const rotation = HourlyRotation(slotsPerDay: 12, zikrCount: 12);
      expect(rotation.fitsInOneDay, isTrue);
    });

    test('a single-hour range walks through every zekr', () {
      const rotation = HourlyRotation(slotsPerDay: 1, zikrCount: 12);
      expect(rotation.daysToCoverAll, 12);
      expect([for (var d = 0; d < 13; d++) dayOf(rotation, d).single], [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, //
      ]);
    });
  });

  group('HourlyRotation.epochDay', () {
    test('consecutive dates are one apart, across a DST change', () {
      // Spring-forward in most of Europe / the US falls in late March.
      for (var day = 20; day < 40; day++) {
        final a = DateTime(2026, 3, day);
        final b = DateTime(2026, 3, day + 1);
        expect(HourlyRotation.epochDay(b) - HourlyRotation.epochDay(a), 1);
      }
    });

    test('ignores the time of day', () {
      expect(
        HourlyRotation.epochDay(DateTime(2026, 10, 7, 23, 59)),
        HourlyRotation.epochDay(DateTime(2026, 10, 7)),
      );
    });
  });

  group('HourlyRotation.fireTime', () {
    test('a plain range fires on its own date', () {
      final hours = const NotificationWindow(startHour: 9, endHour: 13).hours;
      expect(
        HourlyRotation.fireTime(DateTime(2026, 10, 7), hours, 4, 10),
        DateTime(2026, 10, 7, 13, 10),
      );
    });

    test('the after-midnight tail of a wrapping range falls on the next date',
        () {
      final hours = const NotificationWindow(startHour: 22, endHour: 2).hours;
      expect(
        HourlyRotation.fireTime(DateTime(2026, 10, 7), hours, 0, 0),
        DateTime(2026, 10, 7, 22),
      );
      expect(
        HourlyRotation.fireTime(DateTime(2026, 10, 7), hours, 3, 0),
        DateTime(2026, 10, 8, 1),
      );
    });
  });

  group('HourlyRotation.currentWindowDay', () {
    const morning = NotificationWindow(startHour: 9, endHour: 13);
    const night = NotificationWindow(startHour: 22, endHour: 2);

    test('before or inside today\'s range it is today', () {
      expect(
        HourlyRotation.currentWindowDay(morning, DateTime(2026, 10, 7, 6)),
        DateTime(2026, 10, 7),
      );
      expect(
        HourlyRotation.currentWindowDay(morning, DateTime(2026, 10, 7, 13, 30)),
        DateTime(2026, 10, 7),
      );
    });

    test('after today\'s range has ended it is tomorrow', () {
      expect(
        HourlyRotation.currentWindowDay(morning, DateTime(2026, 10, 7, 14)),
        DateTime(2026, 10, 8),
      );
    });

    test('after midnight inside a wrapping range it is the day it began', () {
      expect(
        HourlyRotation.currentWindowDay(night, DateTime(2026, 10, 8, 1)),
        DateTime(2026, 10, 7),
      );
    });

    test('in the gap of a wrapping range it is tonight', () {
      expect(
        HourlyRotation.currentWindowDay(night, DateTime(2026, 10, 8, 12)),
        DateTime(2026, 10, 8),
      );
    });
  });
}
