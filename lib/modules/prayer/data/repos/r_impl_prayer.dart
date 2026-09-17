import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_calc.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_calendar_cache.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_methods_cache.dart';
import 'package:quran/modules/prayer/data/datasources/remote/ds_remote_prayer.dart';
import 'package:quran/modules/prayer/data/models/m_aladhan_day.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_day.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';
import 'package:quran/modules/prayer/services/prayer_refresh_policy.dart';

/// Aladhan-backed implementation of [RPrayer].
///
/// It owns the resolution order the whole feature rests on:
///
///   1. a cached month that is still fresh and still applies here,
///   2. a fetch from Aladhan,
///   3. that same cache even when stale or fetched somewhere else,
///   4. on-device astronomy,
///   5. and only then a failure.
///
/// Nothing below step 4 invents times, and step 3/4 results are labelled
/// [EPrayerSource.staleCache] / [EPrayerSource.calculated] so the UI can say
/// so rather than present them as live.
class RImplPrayer implements RPrayer {
  RImplPrayer({
    required DSRemotePrayer remote,
    required DSPrayerCalendarCache cache,
    required DSPrayerMethodsCache methodsCache,
    DSPrayerCalc? calc,
  }) : _remote = remote,
       _cache = cache,
       _methodsCache = methodsCache,
       _calc = calc ?? DSPrayerCalc();

  final DSRemotePrayer _remote;
  final DSPrayerCalendarCache _cache;
  final DSPrayerMethodsCache _methodsCache;
  final DSPrayerCalc _calc;

  /// Session-lifetime memo, so opening the prayer screen, rebuilding the
  /// notification window and refreshing the home card don't each re-decode the
  /// same month out of Hive. Validated exactly like the disk cache.
  final Map<String, EPrayerCalendar> _memory = {};

  @override
  Future<Either<Failure, EPrayerCalendar>> getCalendar(
    ParamPrayerCalendar p,
  ) async {
    final key = '${p.year}-${p.month}#${p.settings.cacheSignature}';

    if (!p.forceRefresh) {
      final usable = _usableCached(key, p);
      if (usable != null) {
        return Right(usable.copyWith(source: EPrayerSource.cache));
      }
    }

    if (p.cacheOnly) {
      final stored = _storedCalendar(key, p);
      return stored == null
          ? Left(
              Failure.cacheFailure(
                message: 'No cached prayer calendar for ${p.year}-${p.month}',
              ),
            )
          : Right(stored.copyWith(source: EPrayerSource.staleCache));
    }

    try {
      final days = await _remote.calendar(
        latitude: p.latitude,
        longitude: p.longitude,
        year: p.year,
        month: p.month,
        settings: p.settings,
      );
      final calendar = _toCalendar(days, p);
      if (calendar == null) {
        throw const FormatException('No day in the month could be parsed');
      }
      _memory[key] = calendar;
      await _cache.write(calendar);
      AppLogger.info(
        'Prayer calendar ${p.year}-${p.month} fetched '
        '(tz: ${calendar.timezone}, method: ${calendar.methodId} '
        '${calendar.methodName}, days: ${calendar.days.length})',
        tag: 'RImplPrayer',
      );
      return Right(calendar);
    } on DioException catch (e) {
      return _degrade(key, p, _failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPrayer.getCalendar',
        error: e,
        stackTrace: st,
      );
      return _degrade(key, p, Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EDailyPrayerTimes>> getDay(ParamPrayerDay p) async {
    final day = p.day;
    final calendar = await getCalendar(
      ParamPrayerCalendar(
        latitude: p.latitude,
        longitude: p.longitude,
        year: day.year,
        month: day.month,
        settings: p.settings,
        countryCode: p.countryCode,
      ),
    );

    final fromMonth = calendar.fold(
      (_) => null,
      (value) => value.dayFor(day),
    );
    if (fromMonth != null) return Right(fromMonth);

    // The month resolved but doesn't hold this date (a short/partial cached
    // month), or the month itself failed. Ask for the single day directly
    // before giving up on the network.
    try {
      final parsed = await _remote.timings(
        latitude: p.latitude,
        longitude: p.longitude,
        settings: p.settings,
        date: day,
      );
      final domain = parsed.toDomain();
      if (domain != null) return Right(domain);
    } catch (e) {
      AppLogger.warning(
        'Single-day prayer fetch failed for $day: $e',
        tag: 'RImplPrayer',
      );
    }

    final calculated = _calculateDay(p, calendar);
    if (calculated != null) return Right(calculated);

    return calendar.fold(
      Left.new,
      (_) => Left(
        Failure.unexpectedFailure(message: 'No prayer times available for $day'),
      ),
    );
  }

  @override
  Future<Either<Failure, List<ECalculationMethod>>>
  getCalculationMethods() async {
    final cached = _methodsCache.read();
    final fetchedAt = _methodsCache.fetchedAt();
    final fresh =
        cached.isNotEmpty &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) <
            PrayerRefreshPolicy.methodsFreshFor;
    if (fresh) return Right(cached);

    try {
      final methods = await _remote.methods();
      await _methodsCache.write(methods);
      return Right(methods);
    } catch (e) {
      AppLogger.warning(
        'Calculation-methods fetch failed ($e) — using cache/fallback',
        tag: 'RImplPrayer',
      );
      // The picker must never be empty: a stale cache beats the bundled list,
      // and the bundled list beats nothing at all.
      return Right(cached.isNotEmpty ? cached : ECalculationMethod.fallback);
    }
  }

  /// Whatever is stored for this month and these settings, fresh or not, near
  /// or far. The raw read behind both the freshness check and the fallbacks.
  EPrayerCalendar? _storedCalendar(String key, ParamPrayerCalendar p) {
    final cached =
        _memory[key] ??
        _cache.read(
          year: p.year,
          month: p.month,
          settingsSignature: p.settings.cacheSignature,
        );
    if (cached != null) _memory[key] = cached;
    return cached;
  }

  /// A cached month that is still fresh AND still applies where the user is.
  EPrayerCalendar? _usableCached(String key, ParamPrayerCalendar p) {
    final cached = _storedCalendar(key, p);
    if (cached == null) return null;

    if (PrayerRefreshPolicy.hasMovedMeaningfully(
      fromLatitude: cached.latitude,
      fromLongitude: cached.longitude,
      toLatitude: p.latitude,
      toLongitude: p.longitude,
    )) {
      return null; // travelled — these times are for somewhere else
    }
    if (PrayerRefreshPolicy.isStale(cached.fetchedAt)) return null;
    return cached;
  }

  /// Steps 3 and 4 of the resolution order, after the network has failed.
  ///
  /// The cache is re-read WITHOUT the freshness and distance checks on
  /// purpose: an out-of-date month, or one fetched in the city the user just
  /// left, is still far better than an empty prayer screen — it is simply
  /// labelled as such.
  Either<Failure, EPrayerCalendar> _degrade(
    String key,
    ParamPrayerCalendar p,
    Failure failure,
  ) {
    AppLogger.warning(
      'Prayer calendar ${p.year}-${p.month} unavailable (${failure.message}) '
      '— falling back',
      tag: 'RImplPrayer',
    );

    final cached = _storedCalendar(key, p);
    if (cached != null) {
      return Right(cached.copyWith(source: EPrayerSource.staleCache));
    }

    try {
      return Right(_calculateMonth(p));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPrayer.calculateMonth',
        error: e,
        stackTrace: st,
      );
      // Surface the original network failure — it is the actionable one.
      return Left(failure);
    }
  }

  /// Builds the whole month on-device. Only reached when the network and every
  /// cache have missed, and never written to the cache — a later online run
  /// must get the authoritative times rather than stay pinned to this.
  ///
  /// No timezone is passed: nothing has ever told this install what the zone at
  /// these coordinates is (that only arrives with an API response, and there
  /// has been none), so the times land in the device's zone. Right for a user
  /// sitting where their phone thinks they are, which is the case this path
  /// exists for; the first successful fetch replaces it.
  EPrayerCalendar _calculateMonth(ParamPrayerCalendar p) {
    final daysInMonth = DateTime(p.year, p.month + 1, 0).day;
    final days = [
      for (var day = 1; day <= daysInMonth; day++)
        _calc.calculate(
          latitude: p.latitude,
          longitude: p.longitude,
          date: DateTime(p.year, p.month, day),
          settings: p.settings,
        ),
    ];
    return EPrayerCalendar(
      year: p.year,
      month: p.month,
      latitude: p.latitude,
      longitude: p.longitude,
      timezone: days.first.timezone,
      settingsSignature: p.settings.cacheSignature,
      fetchedAt: DateTime.now(),
      days: days,
      methodId: days.first.calculationMethodId,
      source: EPrayerSource.calculated,
    );
  }

  EDailyPrayerTimes? _calculateDay(
    ParamPrayerDay p,
    Either<Failure, EPrayerCalendar> calendar,
  ) {
    try {
      return _calc.calculate(
        latitude: p.latitude,
        longitude: p.longitude,
        date: p.day,
        settings: p.settings,
        // Keep an offline day on the same authority and zone the cached online
        // days used, so the two don't visibly disagree.
        resolvedMethodId: calendar.fold((_) => null, (c) => c.methodId),
        timezone: calendar.fold((_) => null, (c) => c.timezone),
      );
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPrayer.calculateDay',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Assembles a month from the parsed API days.
  ///
  /// The calendar-level timezone and method come from the days themselves —
  /// in automatic mode that is the ONLY place the authority Aladhan chose is
  /// reported, and it is what settings later shows as "Automatic · …".
  EPrayerCalendar? _toCalendar(List<MAladhanDay> days, ParamPrayerCalendar p) {
    final parsed = <EDailyPrayerTimes>[
      for (final day in days)
        if (day.toDomain() case final domain?) domain,
    ];
    if (parsed.isEmpty) return null;

    return EPrayerCalendar(
      year: p.year,
      month: p.month,
      latitude: p.latitude,
      longitude: p.longitude,
      timezone: parsed.first.timezone,
      settingsSignature: p.settings.cacheSignature,
      fetchedAt: DateTime.now(),
      days: parsed,
      methodId: parsed.first.calculationMethodId,
      methodName: parsed.first.calculationMethodName,
    );
  }

  Failure _failureFromDio(DioException e) {
    final msg = e.message ?? 'Network error';
    final code = e.response?.statusCode;
    if (code == 404) return Failure.notFoundFailure(message: msg);
    if (code != null && code >= 500) {
      return Failure.serverFailure(message: msg, statusCode: code);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return Failure.networkFailure(message: msg);
    }
    return Failure.unexpectedFailure(message: msg);
  }
}
