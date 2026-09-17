import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_calendar_cache.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_methods_cache.dart';
import 'package:quran/modules/prayer/data/datasources/remote/ds_remote_prayer.dart';
import 'package:quran/modules/prayer/data/models/m_aladhan_day.dart';
import 'package:quran/modules/prayer/data/repos/r_impl_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_day.dart';

/// A stand-in for the Aladhan client: it either answers with a canned month or
/// fails the way a phone with no signal does.
class _FakeRemote extends DSRemotePrayer {
  _FakeRemote({this.failure});

  final Object? failure;
  int calendarCalls = 0;
  int methodCalls = 0;

  @override
  Future<List<MAladhanDay>> calendar({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required EPrayerSettings settings,
  }) async {
    calendarCalls++;
    final error = failure;
    if (error != null) throw error;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return [
      for (var day = 1; day <= daysInMonth; day++)
        MAladhanDay.tryParse(_dayNode(year, month, day)) ??
            (throw StateError('fixture did not parse')),
    ];
  }

  @override
  Future<List<ECalculationMethod>> methods() async {
    methodCalls++;
    final error = failure;
    if (error != null) throw error;
    return const [ECalculationMethod(id: 5, name: 'Egyptian')];
  }

  Map<String, dynamic> _dayNode(int year, int month, int day) => {
    'timings': const {
      'Fajr': '05:05',
      'Sunrise': '06:34',
      'Dhuhr': '12:54',
      'Asr': '16:27',
      'Sunset': '19:13',
      'Maghrib': '19:13',
      'Isha': '20:32',
    },
    'date': {
      'gregorian': {
        'date': '${_two(day)}-${_two(month)}-$year',
      },
      'hijri': const {'date': '23-03-1448'},
    },
    'meta': const {
      'timezone': 'Africa/Cairo',
      'method': {'id': 5, 'name': 'Egyptian General Authority of Survey'},
    },
  };

  static String _two(int value) => value.toString().padLeft(2, '0');
}

void main() {
  AppTimezone.ensureInitialised();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('prayer_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(DSPrayerCalendarCache.boxName);
    await Hive.openBox<String>(DSPrayerMethodsCache.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await Hive.box<String>(DSPrayerCalendarCache.boxName).clear();
    await Hive.box<String>(DSPrayerMethodsCache.boxName).clear();
  });

  RImplPrayer repoWith(DSRemotePrayer remote) => RImplPrayer(
    remote: remote,
    cache: DSPrayerCalendarCache(),
    methodsCache: DSPrayerMethodsCache(),
  );

  ParamPrayerCalendar params({
    double latitude = 30.0444,
    double longitude = 31.2357,
    EPrayerSettings settings = EPrayerSettings.defaults,
  }) => ParamPrayerCalendar(
    latitude: latitude,
    longitude: longitude,
    year: 2026,
    month: 9,
    settings: settings,
  );

  EPrayerCalendar unwrap(Either<Failure, EPrayerCalendar> either) => either.fold(
    (failure) => throw StateError('expected a calendar, got $failure'),
    (calendar) => calendar,
  );

  final offline = DioException.connectionError(
    requestOptions: RequestOptions(),
    reason: 'no internet',
  );

  group('resolution order', () {
    test('a first fetch comes from the network and is cached', () async {
      final remote = _FakeRemote();
      final result = await repoWith(remote).getCalendar(params());
      final calendar = unwrap(result);

      expect(calendar.source, EPrayerSource.network);
      expect(calendar.days, hasLength(30));
      expect(calendar.methodId, 5);
      expect(calendar.methodName, 'Egyptian General Authority of Survey');
      expect(calendar.timezone, 'Africa/Cairo');
      expect(remote.calendarCalls, 1);
      expect(
        Hive.box<String>(DSPrayerCalendarCache.boxName).length,
        1,
        reason: 'the month must be on disk for the next open',
      );
    });

    test('a second open is served from cache without touching the API', () async {
      final remote = _FakeRemote();
      await repoWith(remote).getCalendar(params());

      // A NEW repo, so this reads the disk cache rather than the session memo.
      final second = _FakeRemote();
      final calendar = unwrap(await repoWith(second).getCalendar(params()));

      expect(calendar.source, EPrayerSource.cache);
      expect(second.calendarCalls, 0);
    });

    test('forceRefresh goes back to the network even with a fresh cache', () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final remote = _FakeRemote();
      final calendar = unwrap(
        await repoWith(remote).getCalendar(
          ParamPrayerCalendar(
            latitude: 30.0444,
            longitude: 31.2357,
            year: 2026,
            month: 9,
            settings: EPrayerSettings.defaults,
            forceRefresh: true,
          ),
        ),
      );

      expect(remote.calendarCalls, 1);
      expect(calendar.source, EPrayerSource.network);
    });

    test('offline with a cached month serves it, marked stale', () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final calendar = unwrap(
        await repoWith(_FakeRemote(failure: offline)).getCalendar(
          ParamPrayerCalendar(
            latitude: 30.0444,
            longitude: 31.2357,
            year: 2026,
            month: 9,
            settings: EPrayerSettings.defaults,
            forceRefresh: true, // force it past the fresh-cache shortcut
          ),
        ),
      );

      expect(calendar.source, EPrayerSource.staleCache);
      expect(calendar.days, hasLength(30));
    });

    test('offline with no cache at all falls back to on-device calculation',
        () async {
      final calendar = unwrap(
        await repoWith(_FakeRemote(failure: offline)).getCalendar(params()),
      );

      expect(calendar.source, EPrayerSource.calculated);
      expect(calendar.days, hasLength(30));
      // Never fabricated: a calculated day still has to be a plausible one.
      final day = calendar.days.first;
      expect(day.fajr.isBefore(day.dhuhr), isTrue);
      expect(day.dhuhr.isBefore(day.isha), isTrue);
    });

    test('cacheOnly answers from storage and never reaches the network',
        () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final remote = _FakeRemote();
      final calendar = unwrap(
        await repoWith(remote).getCalendar(
          ParamPrayerCalendar(
            latitude: 30.0444,
            longitude: 31.2357,
            year: 2026,
            month: 9,
            settings: EPrayerSettings.defaults,
            cacheOnly: true,
            forceRefresh: true, // even asked to refresh, it must not fetch
          ),
        ),
      );

      expect(remote.calendarCalls, 0);
      expect(calendar.days, hasLength(30));
    });

    test('cacheOnly with nothing stored fails rather than calculating', () async {
      // The first paint must not flash approximate times that are replaced a
      // second later by the real ones.
      final remote = _FakeRemote();
      final result = await repoWith(remote).getCalendar(
        ParamPrayerCalendar(
          latitude: 30.0444,
          longitude: 31.2357,
          year: 2026,
          month: 9,
          settings: EPrayerSettings.defaults,
          cacheOnly: true,
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(remote.calendarCalls, 0);
    });

    test('a calculated month is not written to the cache', () async {
      await repoWith(_FakeRemote(failure: offline)).getCalendar(params());

      expect(
        Hive.box<String>(DSPrayerCalendarCache.boxName).length,
        0,
        reason: 'a later online run must get the authoritative times',
      );
    });
  });

  group('cache invalidation', () {
    test('travelling past the threshold refetches', () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final remote = _FakeRemote();
      // Cairo → Makkah.
      final calendar = unwrap(
        await repoWith(remote).getCalendar(
          params(latitude: 21.4225, longitude: 39.8262),
        ),
      );

      expect(remote.calendarCalls, 1);
      expect(calendar.source, EPrayerSource.network);
    });

    test('moving within the threshold does not', () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final remote = _FakeRemote();
      await repoWith(remote).getCalendar(
        params(latitude: 30.0500, longitude: 31.2400),
      );

      expect(remote.calendarCalls, 0);
    });

    test('changing the Asr school refetches instead of reusing the month',
        () async {
      await repoWith(_FakeRemote()).getCalendar(params());

      final remote = _FakeRemote();
      await repoWith(remote).getCalendar(
        params(
          settings: const EPrayerSettings(asrSchool: EAsrSchool.hanafi),
        ),
      );

      expect(remote.calendarCalls, 1);
      expect(
        Hive.box<String>(DSPrayerCalendarCache.boxName).length,
        2,
        reason: 'the two settings must occupy separate entries',
      );
    });
  });

  group('calculation methods', () {
    test('are fetched and cached', () async {
      final remote = _FakeRemote();
      final repo = repoWith(remote);

      final first = await repo.getCalculationMethods();
      expect(first.getOrElse(() => const []), hasLength(1));
      expect(remote.methodCalls, 1);

      // A fresh repo reads the cache instead of the network.
      final second = _FakeRemote();
      await repoWith(second).getCalculationMethods();
      expect(second.methodCalls, 0);
    });

    test('never come back empty, even offline on a first run', () async {
      final result = await repoWith(
        _FakeRemote(failure: offline),
      ).getCalculationMethods();

      final methods = result.getOrElse(() => const []);
      expect(methods, isNotEmpty);
      expect(
        methods.any((m) => m.id == ECalculationMethod.customId),
        isFalse,
        reason: 'CUSTOM is not a pickable authority',
      );
    });
  });

  group('single day', () {
    test('is served from the month that contains it', () async {
      final remote = _FakeRemote();
      final repo = repoWith(remote);
      await repo.getCalendar(params());

      final day = await repo.getDay(
        ParamPrayerDay(
          latitude: 30.0444,
          longitude: 31.2357,
          settings: EPrayerSettings.defaults,
          date: DateTime(2026, 9, 12),
        ),
      );

      expect(day.isRight(), isTrue);
      expect(remote.calendarCalls, 1, reason: 'no extra request for one day');
    });
  });
}
