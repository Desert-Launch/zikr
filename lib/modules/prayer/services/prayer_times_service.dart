import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_calendar.dart';
import 'package:quran/modules/prayer/services/prayer_refresh_policy.dart';

/// The one place prayer times are assembled for the whole app.
///
/// Both consumers — the prayer screen's cubit and the adhan scheduler — used
/// to resolve location, settings and timings independently, which is how they
/// drifted apart: one applied a country method map, the other clamped a
/// madhab index, and neither knew what the API had actually calculated with.
/// They now share this, so what is on screen and what will ring are the same
/// numbers by construction.
///
/// Location handling is deliberately *not* folded in: [DSLocation] throws
/// [LocationException] with a reason the prayer screen renders and acts on,
/// and swallowing that into a generic failure would cost the user the one
/// button that fixes their problem. Callers resolve a location themselves and
/// pass it here.
class PrayerTimesService {
  PrayerTimesService({
    required UCGetPrayerCalendar getCalendar,
    required BoxPrayerSettings settings,
    required DSLastLocation lastLocation,
  }) : _getCalendar = getCalendar,
       _settings = settings,
       _lastLocation = lastLocation;

  final UCGetPrayerCalendar _getCalendar;
  final BoxPrayerSettings _settings;
  final DSLastLocation _lastLocation;

  /// How far ahead the assembled window reaches. Two months are fetched, so
  /// this is bounded by data rather than by the horizon: the adhan scheduler
  /// arms up to a fortnight, the screen needs today and tomorrow.
  static const int _windowDays = 45;

  /// Builds the schedule for [location].
  ///
  /// Fetches the current month and prefetches the next, so the last days of a
  /// month — and the notification window that reaches past them — never fall
  /// off the end of the cache. The next month is best-effort: failing to
  /// prefetch it must not cost the user this month's times.
  ///
  /// [forceRefresh] bypasses the freshness shortcut (pull-to-refresh, or a
  /// settings change that already invalidated the entry). [cacheOnly] answers
  /// from storage or not at all — the first-paint path, which must not delay
  /// the screen on a request or race the live refresh that follows it.
  Future<Either<Failure, EPrayerSchedule>> scheduleFor(
    LocationResult location, {
    bool forceRefresh = false,
    bool cacheOnly = false,
    DateTime? now,
  }) async {
    final settings = _settings.calculation();
    final today = now ?? DateTime.now();
    final months = PrayerRefreshPolicy.monthsToCover(today);

    final base = ParamPrayerCalendar(
      latitude: location.latitude,
      longitude: location.longitude,
      year: months.first.$1,
      month: months.first.$2,
      settings: settings,
      countryCode: location.countryCode,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );

    EPrayerCalendar? currentMonth;
    Failure? currentFailure;
    (await _getCalendar(base)).fold(
      (failure) => currentFailure = failure,
      (calendar) => currentMonth = calendar,
    );
    final resolved = currentMonth;
    if (resolved == null) {
      return Left(
        currentFailure ??
            Failure.unexpectedFailure(message: 'Prayer calendar unavailable'),
      );
    }

    // Best-effort prefetch. A failure here is logged and dropped: this month's
    // times are already in hand and are what the user is looking at.
    final nextMonth = await _getCalendar(
      base.forMonth(months.last.$1, months.last.$2),
    );
    final upcoming = nextMonth.fold((failure) {
      AppLogger.warning(
        'Next-month prefetch failed (${failure.message})',
        tag: 'PrayerTimesService',
      );
      return null;
    }, (value) => value);

    await _rememberResolution(resolved, location);

    return Right(
      _assemble(
        location: location,
        current: resolved,
        upcoming: upcoming,
        mode: settings.mode,
        today: today,
      ),
    );
  }

  /// Records what the API actually resolved: the authority (so settings can
  /// name it in automatic mode, and the offline fallback can match it) and the
  /// IANA zone (so a later run can tell it has crossed into another one).
  Future<void> _rememberResolution(
    EPrayerCalendar calendar,
    LocationResult location,
  ) async {
    // Nothing to record from a locally-computed month — it reports the method
    // it guessed with, which is not an answer from the API.
    if (calendar.source == EPrayerSource.calculated) return;
    await _settings.saveResolvedMethod(calendar.methodId, calendar.methodName);
    if (calendar.timezone.isNotEmpty) {
      await _lastLocation.writeTimezone(calendar.timezone);
    }
  }

  EPrayerSchedule _assemble({
    required LocationResult location,
    required EPrayerCalendar current,
    required EPrayerCalendar? upcoming,
    required ECalculationMode mode,
    required DateTime today,
  }) {
    // From yesterday, so the pre-Fajr countdown window has a real Isha to
    // start from rather than an approximation.
    final from = DateTime(today.year, today.month, today.day - 1);
    final horizon = DateTime(from.year, from.month, from.day + _windowDays);

    final days = <EDailyPrayerTimes>[
      ...current.days,
      if (upcoming != null) ...upcoming.days,
    ]..sort((a, b) => a.date.compareTo(b.date));

    // The worst of the two sources wins: a month served from a stale cache
    // still makes the whole schedule stale, and the UI should say so.
    final source = _worstSource(current.source, upcoming?.source);

    return EPrayerSchedule(
      latitude: current.latitude,
      longitude: current.longitude,
      cityName: location.label,
      countryCode: location.countryCode,
      timezone: current.timezone,
      days: days
          .where((day) => !day.date.isBefore(from) && day.date.isBefore(horizon))
          .toList(growable: false),
      source: source,
      fetchedAt: current.fetchedAt,
      methodId: current.methodId,
      methodName: current.methodName,
      mode: mode,
    );
  }

  EPrayerSource _worstSource(EPrayerSource a, EPrayerSource? b) {
    if (b == null) return a;
    // Ordered best → worst; the later of the two in this list wins.
    const ranking = [
      EPrayerSource.network,
      EPrayerSource.cache,
      EPrayerSource.staleCache,
      EPrayerSource.calculated,
    ];
    return ranking.indexOf(a) >= ranking.indexOf(b) ? a : b;
  }
}
