import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/prayer/services/prayer_refresh_policy.dart';
import 'package:quran/modules/prayer/services/prayer_times_service.dart';

/// App-wide prayer-times singleton.
///
/// Paints from the last known location on construction so the screen is never
/// empty while a GPS fix is acquired — that first pass normally resolves
/// entirely out of the monthly cache and touches no network at all. [refresh]
/// then takes a live fix.
///
/// Adhan notification scheduling (the rolling window) is delegated to
/// [AdhanScheduler], and only rebuilt when something that changes prayer times
/// actually changed — a fresh location, a new timezone, or a settings edit —
/// so opening the screen does not churn the OS schedule.
class CBPrayerTimes extends Cubit<SPrayerTimes> {
  CBPrayerTimes({
    required DSLocation location,
    required DSLastLocation lastLocation,
    required PrayerTimesService times,
    required AdhanScheduler scheduler,
  }) : _location = location,
       _lastLocation = lastLocation,
       _times = times,
       _scheduler = scheduler,
       super(const SPrayerTimes()) {
    unawaited(_hydrateFromCache());
  }

  final DSLocation _location;
  final DSLastLocation _lastLocation;
  final PrayerTimesService _times;
  final AdhanScheduler _scheduler;

  bool _refreshing = false;

  /// First paint from the last known fix. Costs no GPS prompt and, with a
  /// cached month, no network either.
  Future<void> _hydrateFromCache() async {
    final cached = _lastLocation.read();
    if (cached == null) return;
    final result = await _times.scheduleFor(cached, cacheOnly: true);
    if (isClosed) return;
    result.fold(
      (failure) => AppLogger.info(
        'No cached prayer times to hydrate (${failure.message})',
        tag: 'CBPrayerTimes',
      ),
      (schedule) => emit(
        state.copyWith(status: PrayerLoadStatus.success, schedule: schedule),
      ),
    );
  }

  /// The action behind the prayer screen's retry button.
  ///
  /// [refresh] already re-asks for the permission — `DSLocation` requests it on
  /// every attempt — so for an ordinary refusal a plain retry is the whole fix,
  /// and the OS dialog comes back up.
  ///
  /// It is the other two cases that need this method. With device location
  /// switched off no dialog can appear at all, and after a permanent refusal
  /// the OS declines every request without showing one — so retrying would
  /// re-run the same failure and the button would look broken. There the only
  /// thing that moves the user forward is the settings page that owns the
  /// decision; [SNPrayerTimes] refreshes when they come back from it.
  Future<void> retry() async {
    final failure = state.locationFailure;
    if (failure == null || !failure.needsSystemSettings) {
      await refresh();
      return;
    }
    if (failure == ELocationFailure.serviceDisabled) {
      await _location.openLocationSettings();
    } else {
      await _location.openAppSettings();
    }
  }

  /// Takes a live GPS fix, resolves the schedule for it, and rebuilds the
  /// adhan window if the result moved.
  ///
  /// [force] skips the cache-freshness shortcut — pull-to-refresh, and the
  /// path a settings change takes.
  Future<void> refresh({bool force = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      emit(state.copyWith(status: PrayerLoadStatus.loading, clearError: true));

      final location = await _resolveLocation();
      if (location == null) return; // state already set by the resolver

      final previous = state.schedule;
      final result = await _times.scheduleFor(location, forceRefresh: force);
      if (isClosed) return;

      result.fold(
        (failure) {
          AppLogger.warning(
            'Prayer times unavailable: ${failure.message}',
            tag: 'CBPrayerTimes',
          );
          // Keep showing whatever is already there; only surface an error when
          // the screen would otherwise be blank.
          emit(
            state.hasTimes
                ? state.copyWith(status: PrayerLoadStatus.success)
                : state.copyWith(
                    status: PrayerLoadStatus.error,
                    error: failure.message,
                  ),
          );
        },
        (schedule) {
          emit(
            state.copyWith(
              status: PrayerLoadStatus.success,
              schedule: schedule,
            ),
          );
          _logResolution(schedule);
          if (_shouldReschedule(previous, schedule)) {
            // Don't block the screen on a fortnight of notification work.
            unawaited(_scheduler.reschedule());
          }
        },
      );
    } finally {
      _refreshing = false;
    }
  }

  /// Re-resolves everything after the user changes a calculation setting, and
  /// rebuilds the notification window — the times that will ring have to match
  /// the ones now on screen.
  Future<void> onSettingsChanged() async {
    await refresh(force: true);
    unawaited(_scheduler.reschedule());
  }

  /// A live fix, falling back to the last known one.
  ///
  /// Returns null when there is nothing to work with, having already emitted
  /// the state the screen should show for that case.
  Future<LocationResult?> _resolveLocation() async {
    try {
      final fresh = await _location.currentPosition();
      if (fresh != null) {
        await _lastLocation.write(fresh);
        // Carry the zone already known for this place, so the schedule can
        // tell a genuine timezone change from a first-ever fix.
        return fresh.copyWith(timezone: _lastLocation.read()?.timezone);
      }
    } on LocationException catch (e) {
      AppLogger.warning('Location failed: $e', tag: 'CBPrayerTimes');
      final fallback = _lastLocation.read();
      if (fallback != null) return fallback;
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: state.hasTimes
              ? PrayerLoadStatus.success
              : PrayerLoadStatus.permissionDenied,
          error: e.message,
          locationFailure: e.reason,
        ),
      );
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Location lookup',
        error: e,
        stackTrace: st,
        tag: 'CBPrayerTimes',
      );
    }

    final fallback = _lastLocation.read();
    if (fallback != null) return fallback;
    if (!isClosed) {
      emit(
        state.copyWith(
          status: state.hasTimes
              ? PrayerLoadStatus.success
              : PrayerLoadStatus.error,
          error: 'Location unavailable',
        ),
      );
    }
    return null;
  }

  /// Whether this refresh changed anything the OS schedule depends on.
  ///
  /// Rebuilding the window on every open would cancel and re-arm dozens of
  /// notifications for nothing; skipping it after a flight would leave the
  /// adhan ringing on the old country's times. The three things that actually
  /// matter are: there was no schedule before, the times moved to another
  /// zone, or the authority changed.
  bool _shouldReschedule(EPrayerSchedule? previous, EPrayerSchedule current) {
    if (previous == null) return true;
    if (previous.timezone != current.timezone) return true;
    if (previous.methodId != current.methodId) return true;
    return PrayerRefreshPolicy.hasMovedMeaningfully(
      fromLatitude: previous.latitude,
      fromLongitude: previous.longitude,
      toLatitude: current.latitude,
      toLongitude: current.longitude,
    );
  }

  /// Development diagnostics for §21 — everything needed to explain a timing
  /// on a support thread, and nothing that identifies the user.
  ///
  /// Coordinates are rounded to two decimals (~1 km) rather than logged
  /// exactly: enough to tell Cairo from Riyadh when debugging, not enough to
  /// tell a home from a workplace.
  void _logResolution(EPrayerSchedule schedule) {
    AppLogger.info(
      'Prayer times · ${schedule.latitude.toStringAsFixed(2)},'
      '${schedule.longitude.toStringAsFixed(2)} · tz ${schedule.timezone} · '
      'mode ${schedule.mode.name} · method ${schedule.methodId} '
      '${schedule.methodName ?? ''} · source ${schedule.source.name} · '
      'fetched ${schedule.fetchedAt.toIso8601String()} · '
      '${schedule.days.length} days',
      tag: 'CBPrayerTimes',
    );
  }
}
