import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/models/m_aladhan_day.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_calendar_cache.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_next_prayer.dart';
import 'package:timezone/timezone.dart' as tz;

/// The accuracy matrix from the spec, run against real `/v1/calendar`
/// responses rather than hand-written ones.
///
/// The fixtures under `test/fixtures/aladhan/` are live October 2026 months for
/// each location (plus an Oslo June, where Isha falls after midnight), trimmed
/// to the fields the parser reads. They are here because the cases that break
/// prayer times are the ones nobody invents: a DST boundary mid-month, an Isha
/// that belongs to the next calendar day, a regional authority chosen by the
/// API rather than by us.
///
/// Every request that produced them sent nothing but coordinates — Automatic
/// mode — so the method ids below are the API's own choices.
void main() {
  AppTimezone.ensureInitialised();

  const resolver = UCGetNextPrayer();
  const dir = 'test/fixtures/aladhan';

  final manifest =
      (jsonDecode(File('$dir/manifest.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();

  /// The authority Automatic resolved for each place, as observed. A change
  /// here is not necessarily a bug — but it is always something to know about.
  const expectedMethod = {
    'cairo': 5, // Egyptian General Authority of Survey
    'makkah': 4, // Umm Al-Qura
    'dubai': 16, // Dubai
    'istanbul': 13, // Diyanet
    'kuala_lumpur': 17, // JAKIM
    'jakarta': 20, // Kemenag
    'london': 3, // Muslim World League
    'oslo': 3,
    'oslo_june': 3,
    'new_york': 2, // ISNA
  };

  /// Months that contain a DST transition, so both offsets must appear.
  const spansDstChange = {'cairo', 'london', 'oslo'};

  const expectedZone = {
    'cairo': 'Africa/Cairo',
    'makkah': 'Asia/Riyadh',
    'dubai': 'Asia/Dubai',
    'istanbul': 'Europe/Istanbul',
    'kuala_lumpur': 'Asia/Kuala_Lumpur',
    'jakarta': 'Asia/Jakarta',
    'london': 'Europe/London',
    'oslo': 'Europe/Oslo',
    'oslo_june': 'Europe/Oslo',
    'new_york': 'America/New_York',
  };

  List<EDailyPrayerTimes> parse(String name) {
    final body =
        jsonDecode(File('$dir/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    return [
      for (final node in body['data'] as List)
        if (MAladhanDay.tryParse(node)?.toDomain() case final day?) day,
    ];
  }

  for (final entry in manifest) {
    final name = entry['name'] as String;

    group(name, () {
      late List<EDailyPrayerTimes> days;
      setUp(() => days = parse(name));

      test('every day of the month parses', () {
        expect(days, hasLength(entry['days'] as int));
      });

      test('automatic resolved the regional authority and the IANA zone', () {
        expect(days.first.calculationMethodId, expectedMethod[name]);
        expect(days.first.calculationMethodName, isNotEmpty);
        expect(days.first.timezone, expectedZone[name]);
      });

      test('each day\'s prayers run strictly forward', () {
        for (final day in days) {
          final times = day.salahSlots.map((s) => s.time).toList();
          for (var i = 1; i < times.length; i++) {
            expect(
              times[i].isAfter(times[i - 1]),
              isTrue,
              reason: '${day.date}: ${times[i]} must follow ${times[i - 1]}',
            );
          }
          expect(day.sunrise.isAfter(day.fajr), isTrue);
          expect(day.sunrise.isBefore(day.dhuhr), isTrue);
        }
      });

      test('the next prayer is always ahead, and never sunrise', () {
        final zone = AppTimezone.resolve(days.first.timezone);
        for (var i = 0; i < days.length - 1; i++) {
          for (final hour in [0, 4, 7, 13, 17, 20, 23]) {
            final now = tz.TZDateTime(
              zone,
              days[i].date.year,
              days[i].date.month,
              days[i].date.day,
              hour,
            );
            final next = resolver(days: days.sublist(i), now: now);
            expect(next, isNotNull, reason: 'at $now');
            expect(next?.time.isAfter(now), isTrue, reason: 'at $now');
            expect(next?.prayer, isNot(EPrayer.sunrise), reason: 'at $now');
          }
        }
      });

      test('a cache round trip preserves every instant exactly', () {
        final calendar = EPrayerCalendar(
          year: days.first.date.year,
          month: days.first.date.month,
          latitude: (entry['lat'] as num).toDouble(),
          longitude: (entry['lon'] as num).toDouble(),
          timezone: days.first.timezone,
          settingsSignature: 'fixture',
          fetchedAt: DateTime.now(),
          days: days,
        );

        final restored = MPrayerCalendarCache.decode(
          MPrayerCalendarCache.encode(calendar),
        );

        expect(restored?.days, hasLength(days.length));
        for (var i = 0; i < days.length; i++) {
          expect(restored?.days[i].fajr, days[i].fajr);
          expect(restored?.days[i].isha, days[i].isha);
          expect(
            restored?.days[i].fajr.timeZoneOffset,
            days[i].fajr.timeZoneOffset,
          );
        }
      });

      test('the month resolves both sides of its DST boundary', () {
        final offsets = days.map((d) => d.dhuhr.timeZoneOffset).toSet();

        if (spansDstChange.contains(name)) {
          expect(
            offsets,
            hasLength(2),
            reason: 'a fixed offset here would put half the month an hour out',
          );
        } else {
          expect(offsets, hasLength(1));
        }
      });
    });
  }

  test('an Isha past midnight is carried onto the following day', () {
    // Oslo in June: Isha lands at 00:01, i.e. the next calendar day. Attaching
    // it to the day it was listed under would place it before that morning's
    // Fajr and break every ordering above.
    final days = parse('oslo_june');
    final rolled = days.where((d) => d.isha.day != d.date.day);

    expect(rolled, isNotEmpty);
    for (final day in rolled) {
      expect(day.isha.isAfter(day.maghrib), isTrue);
      expect(day.isha.difference(day.date).inHours, lessThan(30));
    }
  });
}
