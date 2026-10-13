import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/utils/helper/date_labels.dart';

void main() {
  // The day on the widget mock: Saturday 29 August 2026 = 15 Rabi al-Awwal 1448.
  final mockDay = DateTime(2026, 8, 29);

  group('DateLabels', () {
    test('weekday in both languages', () {
      expect(DateLabels.weekday(mockDay, lang: 'ar'), 'السبت');
      expect(DateLabels.weekday(mockDay, lang: 'en'), 'Saturday');
    });

    test('gregorian in both languages', () {
      expect(DateLabels.gregorian(mockDay, lang: 'ar'), '29 أغسطس 2026');
      expect(DateLabels.gregorian(mockDay, lang: 'en'), '29 August 2026');
    });

    test('weekday + gregorian reads like the widget date row', () {
      expect(
        DateLabels.weekdayAndGregorian(mockDay, lang: 'ar'),
        'السبت، 29 أغسطس 2026',
      );
      expect(
        DateLabels.weekdayAndGregorian(mockDay, lang: 'en'),
        'Saturday, 29 August 2026',
      );
    });

    test('relativeDay: today, yesterday, then a short date', () {
      final now = DateTime(2026, 10, 12, 0, 10);
      expect(DateLabels.relativeDay(DateTime(2026, 10, 12, 0, 5), now: now, lang: 'ar'), 'اليوم');
      expect(DateLabels.relativeDay(DateTime(2026, 10, 11, 23, 50), now: now, lang: 'en'), 'Yesterday');
      expect(DateLabels.relativeDay(DateTime(2026, 10, 11, 0, 1), now: now, lang: 'ar'), 'أمس');
      expect(DateLabels.relativeDay(DateTime(2026, 10, 10, 9), now: now, lang: 'ar'), '10 أكتوبر');
      expect(DateLabels.relativeDay(DateTime(2026, 3, 1), now: now, lang: 'en'), '1 March');
    });

    test('relativeDay: other years keep the year', () {
      final now = DateTime(2026, 1, 1, 8);
      expect(DateLabels.relativeDay(DateTime(2025, 12, 31, 22), now: now, lang: 'en'), 'Yesterday');
      expect(DateLabels.relativeDay(DateTime(2025, 12, 30), now: now, lang: 'ar'), '30 ديسمبر 2025');
    });

    test('hijri matches the mock', () {
      expect(DateLabels.hijri(mockDay, lang: 'ar'), '15 ربيع الأول 1448 هـ');
      expect(DateLabels.hijri(mockDay, lang: 'en'), '15 Rabi al-Awwal 1448 AH');
    });

    test('hijri: year and month roll over on the tabular calendar', () {
      // The tabular calendar starts 1447 on 27 June 2025 — one day after
      // Umm al-Qura did. That drift is documented on [DateLabels.hijri]; this
      // pins the arithmetic so it cannot silently move.
      expect(DateLabels.hijri(DateTime(2025, 6, 26), lang: 'en'), '29 Dhu al-Hijjah 1446 AH');
      expect(DateLabels.hijri(DateTime(2025, 6, 27), lang: 'en'), '1 Muharram 1447 AH');
      expect(DateLabels.hijri(DateTime(2026, 2, 17), lang: 'ar'), '29 شعبان 1447 هـ');
      expect(DateLabels.hijri(DateTime(2026, 2, 18), lang: 'ar'), '1 رمضان 1447 هـ');
    });
  });
}
