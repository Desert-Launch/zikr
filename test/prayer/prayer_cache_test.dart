import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_calendar_cache.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';
import 'package:quran/modules/prayer/services/prayer_refresh_policy.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  AppTimezone.ensureInitialised();

  final cairo = AppTimezone.resolve('Africa/Cairo');
  final london = AppTimezone.resolve('Europe/London');

  EDailyPrayerTimes cairoDay(int day) {
    tz.TZDateTime at(int hour, int minute) =>
        tz.TZDateTime(cairo, 2026, 9, day, hour, minute);
    return EDailyPrayerTimes(
      date: DateTime(2026, 9, day),
      fajr: at(5, 5),
      sunrise: at(6, 34),
      dhuhr: at(12, 54),
      asr: at(16, 27),
      maghrib: at(19, 13),
      isha: at(20, 32),
      imsak: at(4, 55),
      // 00:54 the FOLLOWING morning — the day-carrying part of the encoding.
      midnight: tz.TZDateTime(cairo, 2026, 9, day + 1, 0, 54),
      timezone: 'Africa/Cairo',
      calculationMethodId: 5,
      calculationMethodName: 'Egyptian General Authority of Survey',
      hijriDate: '23-03-1448',
    );
  }

  EPrayerCalendar calendar({
    String signature = 'mauto-sstandard-hautomatic-t0',
    double latitude = 30.0444,
    double longitude = 31.2357,
    List<EDailyPrayerTimes>? days,
  }) => EPrayerCalendar(
    year: 2026,
    month: 9,
    latitude: latitude,
    longitude: longitude,
    timezone: 'Africa/Cairo',
    settingsSignature: signature,
    fetchedAt: DateTime.utc(2026, 9, 1, 6),
    days: days ?? [for (var d = 1; d <= 30; d++) cairoDay(d)],
    methodId: 5,
    methodName: 'Egyptian General Authority of Survey',
  );

  group('cache key', () {
    test('same month and settings → the same key (a cache hit)', () {
      String keyFor(EPrayerSettings settings) => MPrayerCalendarCache.keyFor(
        year: 2026,
        month: 9,
        settingsSignature: settings.cacheSignature,
      );

      expect(keyFor(EPrayerSettings.defaults), keyFor(EPrayerSettings.defaults));
    });

    test('changing the method, school, high-latitude rule or tune '
        'lands on a different key', () {
      String keyFor(EPrayerSettings settings) => MPrayerCalendarCache.keyFor(
        year: 2026,
        month: 9,
        settingsSignature: settings.cacheSignature,
      );

      const base = EPrayerSettings.defaults;
      final baseKey = keyFor(base);

      expect(
        keyFor(base.copyWith(
          mode: ECalculationMode.manual,
          manualMethodId: 3,
        )),
        isNot(baseKey),
      );
      expect(keyFor(base.copyWith(asrSchool: EAsrSchool.hanafi)), isNot(baseKey));
      expect(
        keyFor(base.copyWith(
          adjustments: const EPrayerAdjustments(fajr: 1),
        )),
        isNot(baseKey),
      );
    });

    test('a different month is a different key', () {
      expect(
        MPrayerCalendarCache.keyFor(year: 2026, month: 9, settingsSignature: 's'),
        isNot(
          MPrayerCalendarCache.keyFor(
            year: 2026,
            month: 10,
            settingsSignature: 's',
          ),
        ),
      );
    });
  });

  group('encode / decode', () {
    test('a month round-trips to the same instants', () {
      final decoded = MPrayerCalendarCache.decode(
        MPrayerCalendarCache.encode(calendar()),
      );

      expect(decoded, isNotNull);
      expect(decoded?.days, hasLength(30));
      expect(decoded?.year, 2026);
      expect(decoded?.month, 9);
      expect(decoded?.timezone, 'Africa/Cairo');
      expect(decoded?.methodId, 5);
      expect(decoded?.methodName, 'Egyptian General Authority of Survey');
      expect(decoded?.latitude, 30.0444);

      final original = calendar().days.first;
      final restored = decoded?.days.first;
      expect(restored?.fajr, original.fajr);
      expect(restored?.isha, original.isha);
      expect(restored?.fajr.timeZoneOffset, original.fajr.timeZoneOffset);
    });

    test('a timing that belongs to the next day keeps its date', () {
      final decoded = MPrayerCalendarCache.decode(
        MPrayerCalendarCache.encode(calendar()),
      );

      expect(decoded?.days.first.midnight?.day, 2);
      expect(decoded?.days.first.date.day, 1);
    });

    test('a cached month re-resolves DST from the zone, not a stored offset', () {
      // Encoded as wall clocks in Europe/London: 24 October is BST, 25 October
      // is GMT. Decoding must produce both offsets.
      final month = EPrayerCalendar(
        year: 2026,
        month: 10,
        latitude: 51.5072,
        longitude: -0.1276,
        timezone: 'Europe/London',
        settingsSignature: 'sig',
        fetchedAt: DateTime.utc(2026, 10, 1),
        days: [
          for (final day in [24, 25])
            EDailyPrayerTimes(
              date: DateTime(2026, 10, day),
              fajr: tz.TZDateTime(london, 2026, 10, day, 5, 0),
              sunrise: tz.TZDateTime(london, 2026, 10, day, 7, 0),
              dhuhr: tz.TZDateTime(london, 2026, 10, day, 12, 0),
              asr: tz.TZDateTime(london, 2026, 10, day, 15, 0),
              maghrib: tz.TZDateTime(london, 2026, 10, day, 17, 0),
              isha: tz.TZDateTime(london, 2026, 10, day, 19, 0),
              timezone: 'Europe/London',
            ),
        ],
      );

      final decoded = MPrayerCalendarCache.decode(
        MPrayerCalendarCache.encode(month),
      );

      expect(decoded?.days[0].dhuhr.timeZoneOffset, const Duration(hours: 1));
      expect(decoded?.days[1].dhuhr.timeZoneOffset, Duration.zero);
      expect(decoded?.days[0].dhuhr.hour, 12);
      expect(decoded?.days[1].dhuhr.hour, 12);
    });

    test('a corrupt entry reads as a miss, not an error', () {
      expect(MPrayerCalendarCache.decode('{not json'), isNull);
      expect(MPrayerCalendarCache.decode(''), isNull);
      expect(MPrayerCalendarCache.decode(null), isNull);
      expect(MPrayerCalendarCache.decode('{"y":2026}'), isNull);
      expect(MPrayerCalendarCache.decode('{"y":2026,"mo":9,"days":[]}'), isNull);
    });

    test('dayFor finds the right day and misses the rest', () {
      final month = calendar();

      expect(month.dayFor(DateTime(2026, 9, 5))?.date.day, 5);
      expect(month.dayFor(DateTime(2026, 10, 5)), isNull);
      expect(month.covers(DateTime(2026, 9, 30)), isTrue);
      expect(month.covers(DateTime(2026, 10, 1)), isFalse);
    });
  });

  group('travel threshold', () {
    test('GPS noise and a walk across town are not a move', () {
      // ~350 m and ~4 km inside Cairo.
      expect(
        PrayerRefreshPolicy.hasMovedMeaningfully(
          fromLatitude: 30.0444,
          fromLongitude: 31.2357,
          toLatitude: 30.0475,
          toLongitude: 31.2357,
        ),
        isFalse,
      );
      expect(
        PrayerRefreshPolicy.hasMovedMeaningfully(
          fromLatitude: 30.0444,
          fromLongitude: 31.2357,
          toLatitude: 30.0800,
          toLongitude: 31.2357,
        ),
        isFalse,
      );
    });

    test('another city is a move', () {
      expect(
        PrayerRefreshPolicy.hasMovedMeaningfully(
          fromLatitude: 30.0444,
          fromLongitude: 31.2357,
          toLatitude: 21.4225,
          toLongitude: 39.8262,
        ),
        isTrue,
      );
    });

    test('the threshold sits between 5 and 10 km', () {
      const from = 30.0444;
      // ~0.09° of latitude ≈ 10 km.
      expect(
        PrayerRefreshPolicy.hasMovedMeaningfully(
          fromLatitude: from,
          fromLongitude: 31.2357,
          toLatitude: from + 0.09,
          toLongitude: 31.2357,
        ),
        isTrue,
      );
      // ~0.045° ≈ 5 km.
      expect(
        PrayerRefreshPolicy.hasMovedMeaningfully(
          fromLatitude: from,
          fromLongitude: 31.2357,
          toLatitude: from + 0.045,
          toLongitude: 31.2357,
        ),
        isFalse,
      );
    });

    test('distance is symmetric and zero for the same point', () {
      expect(
        PrayerRefreshPolicy.distanceBetween(30.0444, 31.2357, 30.0444, 31.2357),
        closeTo(0, 0.001),
      );
      expect(
        PrayerRefreshPolicy.distanceBetween(30.0444, 31.2357, 21.4225, 39.8262),
        closeTo(
          PrayerRefreshPolicy.distanceBetween(
            21.4225,
            39.8262,
            30.0444,
            31.2357,
          ),
          0.001,
        ),
      );
    });
  });

  group('freshness and coverage', () {
    test('a month is fresh for a week and stale after', () {
      final fetched = DateTime.utc(2026, 9, 1);

      expect(
        PrayerRefreshPolicy.isStale(fetched, now: DateTime.utc(2026, 9, 5)),
        isFalse,
      );
      expect(
        PrayerRefreshPolicy.isStale(fetched, now: DateTime.utc(2026, 9, 20)),
        isTrue,
      );
    });

    test('the current AND next month are always covered', () {
      expect(PrayerRefreshPolicy.monthsToCover(DateTime(2026, 9, 5)), [
        (2026, 9),
        (2026, 10),
      ]);
    });

    test('December rolls the prefetch into next January', () {
      expect(PrayerRefreshPolicy.monthsToCover(DateTime(2026, 12, 31)), [
        (2026, 12),
        (2027, 1),
      ]);
    });
  });
}
