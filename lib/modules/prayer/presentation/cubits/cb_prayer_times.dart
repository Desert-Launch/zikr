import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_cache.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/prayer/utils/prayer_method_mapper.dart';

/// App-wide prayer-times singleton. Loads cached times on construct so the
/// UI paints instantly; refreshes via [refresh()]. Adhan notification
/// scheduling (rolling 7-day window) is delegated to [AdhanScheduler].
class CBPrayerTimes extends Cubit<SPrayerTimes> {
  CBPrayerTimes({
    required DSLocation location,
    required BoxPrayerSettings settings,
    required BoxPrayerCache cache,
    required AdhanScheduler scheduler,
    required UCGetPrayerTimes getTimes,
  })  : _location = location,
        _settingsBox = settings,
        _cacheBox = cache,
        _scheduler = scheduler,
        _getTimes = getTimes,
        super(const SPrayerTimes()) {
    _hydrateFromCache();
  }

  final DSLocation _location;
  final BoxPrayerSettings _settingsBox;
  final BoxPrayerCache _cacheBox;
  final AdhanScheduler _scheduler;
  final UCGetPrayerTimes _getTimes;

  void _hydrateFromCache() {
    final cache = _cacheBox.current();
    if (cache == null) return;
    final today = DateTime.now();
    final cached = cache.computedAt;
    if (cached.year != today.year ||
        cached.month != today.month ||
        cached.day != today.day) {
      // Stale → ignore; refresh() will repopulate.
      return;
    }
    emit(state.copyWith(
      status: PrayerLoadStatus.success,
      slots: _slotsFromCache(cache),
      cityName: cache.cityName,
      latitude: cache.latitude,
      longitude: cache.longitude,
      computedAt: cache.computedAt,
    ));
  }

  List<PrayerSlot> _slotsFromCache(MPrayerCache c) => [
        PrayerSlot(prayer: EPrayer.fajr, time: c.fajr),
        PrayerSlot(prayer: EPrayer.sunrise, time: c.sunrise),
        PrayerSlot(prayer: EPrayer.dhuhr, time: c.dhuhr),
        PrayerSlot(prayer: EPrayer.asr, time: c.asr),
        PrayerSlot(prayer: EPrayer.maghrib, time: c.maghrib),
        PrayerSlot(prayer: EPrayer.isha, time: c.isha),
      ];

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

  /// Re-fetches GPS, pulls today's timings from Aladhan, persists to cache,
  /// and reschedules today's notifications.
  Future<void> refresh() async {
    emit(state.copyWith(status: PrayerLoadStatus.loading, clearError: true));
    LocationResult? loc;
    try {
      loc = await _location.currentPosition();
    } on LocationException catch (e) {
      AppLogger.warning('Location failed: $e', tag: 'CBPrayerTimes');
      // Fall back to cache if we have one, else surface a permission error.
      if (state.slots.isEmpty) {
        emit(state.copyWith(
          status: PrayerLoadStatus.permissionDenied,
          error: e.message,
          locationFailure: e.reason,
        ));
      } else {
        emit(state.copyWith(status: PrayerLoadStatus.success));
      }
      return;
    } catch (e, st) {
      AppLogger.error('Location lookup',
          error: e, stackTrace: st, tag: 'CBPrayerTimes');
      emit(state.copyWith(status: PrayerLoadStatus.error, error: e.toString()));
      return;
    }
    if (loc == null) {
      emit(state.copyWith(status: PrayerLoadStatus.error, error: 'Timeout'));
      return;
    }

    final settings = _settingsBox.current();
    final today = DateTime.now();
    final param = ParamPrayerTimes(
      latitude: loc.latitude,
      longitude: loc.longitude,
      method: PrayerMethodMapper.methodForCountry(loc.countryCode),
      school: settings.madhabIndex.clamp(0, 1),
      date: today,
      countryCode: loc.countryCode,
      cityLabel: loc.label,
    );

    final result = await _getTimes(param);
    final cityName = loc.label.isNotEmpty ? loc.label : state.cityName;
    result.fold(
      (failure) {
        AppLogger.warning('Timings fetch failed: ${failure.message}',
            tag: 'CBPrayerTimes');
        // Keep showing whatever we already have; only surface an error when
        // there's nothing on screen.
        if (state.slots.isEmpty) {
          emit(state.copyWith(
            status: PrayerLoadStatus.error,
            error: failure.message,
          ));
        } else {
          emit(state.copyWith(status: PrayerLoadStatus.success));
        }
      },
      (timings) async {
        final slots = _slotsFromTimings(timings);
        await _persist(timings, loc!, cityName);
        emit(state.copyWith(
          status: PrayerLoadStatus.success,
          slots: slots,
          cityName: cityName,
          latitude: loc.latitude,
          longitude: loc.longitude,
          computedAt: DateTime.now(),
        ));
        // Rebuild the rolling adhan window in the background — don't block the
        // UI on 7 days of timing fetches.
        unawaited(_scheduler.reschedule());
        unawaited(_loadTomorrow(loc));
      },
    );
  }

  /// Resolves tomorrow's timings so the card can roll over the moment today's
  /// isha passes, instead of sitting on a spent day until midnight.
  ///
  /// Usually free: [AdhanScheduler] pre-fetches a two-week window into the same
  /// per-date cache [UCGetPrayerTimes] reads through, so this normally returns
  /// without touching the network. Failure is not surfaced — the card falls
  /// back to [SPrayerTimes.nextDaySlots].
  Future<void> _loadTomorrow(LocationResult loc) async {
    final now = DateTime.now();
    final result = await _getTimes(
      ParamPrayerTimes(
        latitude: loc.latitude,
        longitude: loc.longitude,
        method: PrayerMethodMapper.methodForCountry(loc.countryCode),
        school: _settingsBox.current().madhabIndex.clamp(0, 1),
        // Day arithmetic, not a 24h add — DateTime normalises the overflow, so
        // this stays right across month ends and DST.
        date: DateTime(now.year, now.month, now.day + 1),
        countryCode: loc.countryCode,
        cityLabel: loc.label,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => AppLogger.warning(
        "Tomorrow's timings failed: ${failure.message}",
        tag: 'CBPrayerTimes',
      ),
      (timings) => emit(state.copyWith(tomorrowSlots: _slotsFromTimings(timings))),
    );
  }

  List<PrayerSlot> _slotsFromTimings(MPrayerTimings t) => [
        PrayerSlot(prayer: EPrayer.fajr, time: t.fajr),
        PrayerSlot(prayer: EPrayer.sunrise, time: t.sunrise),
        PrayerSlot(prayer: EPrayer.dhuhr, time: t.dhuhr),
        PrayerSlot(prayer: EPrayer.asr, time: t.asr),
        PrayerSlot(prayer: EPrayer.maghrib, time: t.maghrib),
        PrayerSlot(prayer: EPrayer.isha, time: t.isha),
      ];

  Future<void> _persist(
    MPrayerTimings t,
    LocationResult loc,
    String cityName,
  ) =>
      _cacheBox.save(MPrayerCache(
        latitude: loc.latitude,
        longitude: loc.longitude,
        cityName: cityName,
        fajrIso: t.fajr.toIso8601String(),
        sunriseIso: t.sunrise.toIso8601String(),
        dhuhrIso: t.dhuhr.toIso8601String(),
        asrIso: t.asr.toIso8601String(),
        maghribIso: t.maghrib.toIso8601String(),
        ishaIso: t.isha.toIso8601String(),
        computedAtIso: DateTime.now().toIso8601String(),
      ));
}
