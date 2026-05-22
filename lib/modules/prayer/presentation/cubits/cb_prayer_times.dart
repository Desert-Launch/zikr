import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_cache.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

/// App-wide prayer-times singleton. Loads cached times on construct so the
/// UI paints instantly; refreshes via [refresh()] and schedules the 5
/// notifications for today.
///
/// Notification IDs reserved for daily prayers: 1000–1004 (one per prayer).
/// Stable so re-scheduling overwrites the previous day's pending alerts.
class CBPrayerTimes extends Cubit<SPrayerTimes> {
  CBPrayerTimes({
    required DSLocation location,
    required BoxPrayerSettings settings,
    required BoxPrayerCache cache,
    required NotificationsService notifications,
  })  : _location = location,
        _settingsBox = settings,
        _cacheBox = cache,
        _notifications = notifications,
        super(const SPrayerTimes()) {
    _hydrateFromCache();
  }

  final DSLocation _location;
  final BoxPrayerSettings _settingsBox;
  final BoxPrayerCache _cacheBox;
  final NotificationsService _notifications;

  static const _baseNotificationId = 1000;

  static const _prayerOrder = [
    (EPrayer.fajr, _baseNotificationId + 0),
    (EPrayer.dhuhr, _baseNotificationId + 1),
    (EPrayer.asr, _baseNotificationId + 2),
    (EPrayer.maghrib, _baseNotificationId + 3),
    (EPrayer.isha, _baseNotificationId + 4),
  ];

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

  /// Re-fetches GPS, recomputes prayer times, persists to cache, and
  /// reschedules today's notifications.
  Future<void> refresh() async {
    emit(state.copyWith(status: PrayerLoadStatus.loading, clearError: true));
    LocationResult? loc;
    try {
      loc = await _location.currentPosition();
    } on LocationException catch (e) {
      AppLogger.warning('Location failed: ${e.message}', tag: 'CBPrayerTimes');
      // Fall back to cache if we have one, else surface a permission error.
      if (state.slots.isEmpty) {
        emit(state.copyWith(
          status: PrayerLoadStatus.permissionDenied,
          error: e.message,
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
    final params = _paramsFor(settings.calculationMethodIndex,
        settings.madhabIndex);
    final coords = Coordinates(loc.latitude, loc.longitude);
    final today = DateTime.now();
    final pt = PrayerTimes(
      coords,
      DateComponents(today.year, today.month, today.day),
      params,
    );

    final slots = [
      PrayerSlot(prayer: EPrayer.fajr, time: pt.fajr.toLocal()),
      PrayerSlot(prayer: EPrayer.sunrise, time: pt.sunrise.toLocal()),
      PrayerSlot(prayer: EPrayer.dhuhr, time: pt.dhuhr.toLocal()),
      PrayerSlot(prayer: EPrayer.asr, time: pt.asr.toLocal()),
      PrayerSlot(prayer: EPrayer.maghrib, time: pt.maghrib.toLocal()),
      PrayerSlot(prayer: EPrayer.isha, time: pt.isha.toLocal()),
    ];

    await _cacheBox.save(MPrayerCache(
      latitude: loc.latitude,
      longitude: loc.longitude,
      cityName: loc.label,
      fajrIso: pt.fajr.toLocal().toIso8601String(),
      sunriseIso: pt.sunrise.toLocal().toIso8601String(),
      dhuhrIso: pt.dhuhr.toLocal().toIso8601String(),
      asrIso: pt.asr.toLocal().toIso8601String(),
      maghribIso: pt.maghrib.toLocal().toIso8601String(),
      ishaIso: pt.isha.toLocal().toIso8601String(),
      computedAtIso: DateTime.now().toIso8601String(),
    ));

    emit(state.copyWith(
      status: PrayerLoadStatus.success,
      slots: slots,
      cityName: loc.label,
      latitude: loc.latitude,
      longitude: loc.longitude,
      computedAt: DateTime.now(),
    ));

    await _rescheduleNotifications(slots, settings);
  }

  Future<void> _rescheduleNotifications(
      List<PrayerSlot> slots, dynamic settings) async {
    final hasPerm = await _notifications.hasPermission();
    if (!hasPerm) return;

    final notify = (settings.notifyForPrayer as List).cast<bool>();
    for (final entry in _prayerOrder) {
      final prayer = entry.$1;
      final id = entry.$2;
      await _notifications.cancel(id);
      final orderIndex = switch (prayer) {
        EPrayer.fajr => 0,
        EPrayer.dhuhr => 1,
        EPrayer.asr => 2,
        EPrayer.maghrib => 3,
        EPrayer.isha => 4,
        _ => -1,
      };
      if (orderIndex < 0 || orderIndex >= notify.length) continue;
      if (!notify[orderIndex]) continue;

      final slot = slots.firstWhere((s) => s.prayer == prayer);
      if (slot.time.isBefore(DateTime.now())) continue;

      await _notifications.scheduleAt(
        id: id,
        when: slot.time,
        title: 'حان وقت صلاة ${prayer.key}',
        body: 'اضغط لفتح مواقيت الصلاة',
        channel: AppNotificationChannels.prayer,
        payload: NotificationPayload(
          type: 'adhan',
          data: {'prayer': prayer.key},
        ),
      );
    }
  }

  CalculationParameters _paramsFor(int methodIndex, int madhabIndex) {
    final method = CalculationMethod.values[
        methodIndex.clamp(0, CalculationMethod.values.length - 1)];
    final params = method.getParameters();
    params.madhab = Madhab.values[madhabIndex.clamp(0, 1)];
    return params;
  }
}
