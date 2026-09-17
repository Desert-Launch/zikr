import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/models/m_aladhan_day.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';

/// Parsing tests built from real `/v1/timings` and `/v1/calendar` payloads.
void main() {
  setUpAll(AppTimezone.ensureInitialised);

  Map<String, dynamic> payload({
    Map<String, dynamic>? timings,
    String timezone = 'Africa/Cairo',
    String date = '05-09-2026',
    Map<String, dynamic>? method,
  }) => {
    'timings':
        timings ??
        {
          'Fajr': '05:05',
          'Sunrise': '06:34',
          'Dhuhr': '12:54',
          'Asr': '16:27',
          'Sunset': '19:13',
          'Maghrib': '19:13',
          'Isha': '20:32',
          'Imsak': '04:55',
          'Midnight': '00:54',
          'Firstthird': '23:00',
          'Lastthird': '02:47',
        },
    'date': {
      'gregorian': {'date': date},
      'hijri': {'date': '23-03-1448'},
    },
    'meta': {
      'timezone': timezone,
      'method': method ?? {'id': 5, 'name': 'Egyptian General Authority of Survey'},
    },
  };

  /// Parses a fixture that is expected to be valid. `fail` returns `Never`, so
  /// the result promotes to non-null without a `!`.
  EDailyPrayerTimes require(Object? node) {
    final day = MAladhanDay.tryParse(node)?.toDomain();
    if (day == null) fail('fixture was expected to parse, but did not');
    return day;
  }

  group('daily timings', () {
    test('parses the six prayers as instants in the location zone', () {
      final day = MAladhanDay.tryParse(payload())?.toDomain();

      expect(day, isNotNull);
      expect(day?.fajr.hour, 5);
      expect(day?.fajr.minute, 5);
      expect(day?.dhuhr.hour, 12);
      expect(day?.isha.hour, 20);
      expect(day?.date, DateTime(2026, 9, 5));
      // Cairo is UTC+3 in September 2026 (DST).
      expect(day?.fajr.timeZoneOffset, const Duration(hours: 3));
    });

    test('parses the timezone and the resolved method', () {
      final day = MAladhanDay.tryParse(payload())?.toDomain();

      expect(day?.timezone, 'Africa/Cairo');
      expect(day?.calculationMethodId, 5);
      expect(day?.calculationMethodName, 'Egyptian General Authority of Survey');
    });

    test('strips a zone abbreviation from the clock value', () {
      final day = MAladhanDay.tryParse(
        payload(
          timings: {
            'Fajr': '04:13 (EEST)',
            'Sunrise': '05:47 (EEST)',
            'Dhuhr': '12:00 (EEST)',
            'Asr': '15:35 (EEST)',
            'Maghrib': '18:12 (EEST)',
            'Isha': '19:35 (EEST)',
          },
        ),
      )?.toDomain();

      expect(day?.fajr.hour, 4);
      expect(day?.fajr.minute, 13);
    });

    test('an absent optional field does not take the day down', () {
      final day = MAladhanDay.tryParse(
        payload(
          timings: {
            'Fajr': '05:05',
            'Sunrise': '06:34',
            'Dhuhr': '12:54',
            'Asr': '16:27',
            'Maghrib': '19:13',
            'Isha': '20:32',
            // no Imsak, Midnight, Firstthird, Lastthird, Sunset
          },
        ),
      )?.toDomain();

      expect(day, isNotNull);
      expect(day?.imsak, isNull);
      expect(day?.midnight, isNull);
      expect(day?.fajr.hour, 5);
    });
  });

  group('malformed input', () {
    test('a node that is not a map is rejected', () {
      expect(MAladhanDay.tryParse('nonsense'), isNull);
      expect(MAladhanDay.tryParse(null), isNull);
      expect(MAladhanDay.tryParse(const []), isNull);
    });

    test('a response with no timings is rejected', () {
      expect(MAladhanDay.tryParse({'date': {}, 'meta': {}}), isNull);
    });

    test('a day with no parsable date falls back to the requested one', () {
      final day = MAladhanDay.tryParse(
        payload(date: 'not-a-date'),
        fallbackDate: DateTime(2026, 9, 5),
      );

      expect(day?.date, DateTime(2026, 9, 5));
    });

    test('a day with neither a date nor a fallback is rejected', () {
      expect(MAladhanDay.tryParse(payload(date: 'not-a-date')), isNull);
    });

    test('"-----" for a prayer that does not occur yields no day', () {
      // Aladhan answers this at polar latitudes. A day that cannot say when
      // Fajr is has nothing to offer; the caller falls back to calculation.
      final day = MAladhanDay.tryParse(
        payload(
          timings: {
            'Fajr': '-----',
            'Sunrise': '02:00',
            'Dhuhr': '12:54',
            'Asr': '16:27',
            'Maghrib': '23:59',
            'Isha': '-----',
          },
        ),
      )?.toDomain();

      expect(day, isNull);
    });

    test('an unknown timezone still produces a day', () {
      final day = MAladhanDay.tryParse(
        payload(timezone: 'Mars/Olympus_Mons'),
      )?.toDomain();

      expect(day, isNotNull);
      expect(day?.fajr.hour, 5);
    });
  });

  group('timings that cross midnight', () {
    test('an Isha after midnight belongs to the following day', () {
      // Oslo, 21 June: Maghrib 22:44, Isha 00:12. Attaching Isha to the same
      // calendar day would put it eight hours BEFORE that morning's Fajr.
      final day = require(
        payload(
          timezone: 'Europe/Oslo',
          date: '21-06-2026',
          timings: {
            'Fajr': '02:21',
            'Sunrise': '03:54',
            'Dhuhr': '13:21',
            'Asr': '17:48',
            'Sunset': '22:44',
            'Maghrib': '22:44',
            'Isha': '00:12',
          },
        ),
      );

      expect(day.isha.day, 22);
      expect(day.isha.isAfter(day.maghrib), isTrue);
      expect(day.date, DateTime(2026, 6, 21));
    });

    test('midnight and last third roll past midnight, first third does not', () {
      final day = MAladhanDay.tryParse(payload())?.toDomain();

      expect(day?.firstThird?.day, 5); // 23:00 the same evening
      expect(day?.midnight?.day, 6); // 00:54
      expect(day?.lastThird?.day, 6); // 02:47
    });

    test('a tune that puts Maghrib a minute before Sunset does not roll a day', () {
      // The roll-forward rule needs a tolerance: a genuine roll-over is a jump
      // back of most of a day, a tuned minute is not.
      final day = MAladhanDay.tryParse(
        payload(
          timings: {
            'Fajr': '05:05',
            'Sunrise': '06:34',
            'Dhuhr': '12:54',
            'Asr': '16:27',
            'Sunset': '19:13',
            'Maghrib': '19:12',
            'Isha': '20:32',
          },
        ),
      )?.toDomain();

      expect(day?.maghrib.day, 5);
      expect(day?.isha.day, 5);
    });
  });

  group('DST', () {
    test('the same month resolves both offsets around a DST boundary', () {
      // Europe/London leaves BST on 25 October 2026. Both days are parsed with
      // the same code path; the zone decides the offset, not an assumption.
      final before = MAladhanDay.tryParse(
        payload(
          timezone: 'Europe/London',
          date: '24-10-2026',
          timings: {
            'Fajr': '05:48 (BST)',
            'Sunrise': '07:41 (BST)',
            'Dhuhr': '12:45 (BST)',
            'Asr': '15:20 (BST)',
            'Maghrib': '17:48 (BST)',
            'Isha': '19:34 (BST)',
          },
        ),
      )?.toDomain();

      final after = MAladhanDay.tryParse(
        payload(
          timezone: 'Europe/London',
          date: '25-10-2026',
          timings: {
            'Fajr': '04:49 (GMT)',
            'Sunrise': '06:43 (GMT)',
            'Dhuhr': '11:45 (GMT)',
            'Asr': '14:18 (GMT)',
            'Maghrib': '16:46 (GMT)',
            'Isha': '18:32 (GMT)',
          },
        ),
      )?.toDomain();

      expect(before?.dhuhr.timeZoneOffset, const Duration(hours: 1));
      expect(after?.dhuhr.timeZoneOffset, Duration.zero);
      // Both read 11:45/12:45 on their own wall clocks, and the underlying
      // instants are an hour apart plus the calendar day — which is exactly
      // what a notification must fire at.
      expect(before?.dhuhr.hour, 12);
      expect(after?.dhuhr.hour, 11);
    });

    test('New York and Cairo produce different instants for the same clock', () {
      final cairo = MAladhanDay.tryParse(payload())?.toDomain();
      final newYork = MAladhanDay.tryParse(
        payload(timezone: 'America/New_York'),
      )?.toDomain();

      expect(
        cairo?.fajr.toUtc(),
        isNot(equals(newYork?.fajr.toUtc())),
        reason: 'the same wall clock in two zones is not the same moment',
      );
      expect(cairo?.fajr.hour, newYork?.fajr.hour);
    });
  });
}
