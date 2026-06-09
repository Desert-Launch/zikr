import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_times.dart';
import 'package:quran/modules/prayer/utils/prayer_method_mapper.dart';

/// Orchestrates prayer-time → adhan-notification scheduling over a rolling
/// window. Call [reschedule] on app launch, after a settings change, and
/// after the prayer location/timezone changes.
///
/// iOS hard-caps pending notifications at 64, so the window is bounded:
/// 7 days × 5 prayers = 35 alerts, plus optional pre-reminders for the first
/// [_preWindowDays] days. Re-running [reschedule] overwrites cleanly because
/// notification ids are deterministic (day-of-year derived).
class AdhanScheduler {
  AdhanScheduler({
    required NotificationsService notifications,
    required DSLocation location,
    required UCGetPrayerTimes getTimes,
    required BoxPrayerSettings prayerSettings,
    required BoxAdhanSettings adhanSettings,
    required BoxAdhanPreference adhanPrefs,
  }) : _notifications = notifications,
       _location = location,
       _getTimes = getTimes,
       _prayerSettings = prayerSettings,
       _adhanSettings = adhanSettings,
       _adhanPrefs = adhanPrefs;

  final NotificationsService _notifications;
  final DSLocation _location;
  final UCGetPrayerTimes _getTimes;
  final BoxPrayerSettings _prayerSettings;
  final BoxAdhanSettings _adhanSettings;
  final BoxAdhanPreference _adhanPrefs;

  static const int _windowDays = 7;
  static const int _preWindowDays = 4; // keeps total pending ≤ 64 on iOS

  // Dedicated id bands so cancelling our window never touches other features.
  static const int _mainBandStart = 200000;
  static const int _mainBandEnd = 300000;
  static const int _preBandStart = 300000;
  static const int _preBandEnd = 400000;

  /// fajr/dhuhr/asr/maghrib/isha → index used in ids and the per-prayer
  /// notify-toggle list. Sunrise is intentionally excluded (not a salah).
  static const List<EPrayer> _salah = [
    EPrayer.fajr,
    EPrayer.dhuhr,
    EPrayer.asr,
    EPrayer.maghrib,
    EPrayer.isha,
  ];

  bool _running = false;

  /// Cancels the current adhan window and rebuilds it from fresh prayer times.
  /// Safe to call repeatedly; concurrent calls are coalesced.
  Future<void> reschedule() async {
    if (_running) return;
    _running = true;
    try {
      await _cancelWindow();

      final settings = _adhanSettings.current();
      if (!settings.enabled) {
        AppLogger.info(
          'Adhan disabled — window cleared',
          tag: 'AdhanScheduler',
        );
        return;
      }

      if (!await _notifications.hasPermission()) {
        AppLogger.info(
          'No notification permission — skip scheduling',
          tag: 'AdhanScheduler',
        );
        return;
      }

      LocationResult? loc;
      try {
        loc = await _location.currentPosition();
      } catch (e) {
        AppLogger.warning(
          'Adhan scheduling: location failed ($e)',
          tag: 'AdhanScheduler',
        );
        return;
      }
      if (loc == null) return;

      final prayer = _prayerSettings.current();
      final notify = prayer.notifyForPrayer;
      final method = PrayerMethodMapper.methodForCountry(loc.countryCode);

      // Resolve the adhan voice → its bundled clip (or full clip when the user
      // opted into Android background full-adhan). iOS always uses the short
      // .caf (Apple's 30s cap).
      final bgFull =
          settings.androidBackgroundFullAdhan &&
          settings.playbackMode == 'full';
      final now = DateTime.now();

      for (var dayOffset = 0; dayOffset < _windowDays; dayOffset++) {
        final date = DateTime(now.year, now.month, now.day + dayOffset);
        final result = await _getTimes(
          ParamPrayerTimes(
            latitude: loc.latitude,
            longitude: loc.longitude,
            method: method,
            school: prayer.madhabIndex.clamp(0, 1),
            date: date,
            countryCode: loc.countryCode,
            cityLabel: loc.label,
          ),
        );

        final timings = result.fold((_) => null, (t) => t);
        if (timings == null) continue; // skip this day, keep going

        await _scheduleDay(
          date: date,
          timings: timings,
          notify: notify,
          settings: settings,
          voiceIdPerPrayer: prayer.adhanIdPerPrayer ?? const {},
          defaultVoiceId: _adhanPrefs.current().defaultAdhanId,
          bgFull: bgFull,
          scheduledPre: dayOffset < _preWindowDays,
          now: now,
        );
      }
    } finally {
      _running = false;
    }
  }

  /// Cancels every adhan notification so a disabled master switch leaves
  /// nothing pending.
  Future<void> cancelAll() => _cancelWindow();

  Future<void> _scheduleDay({
    required DateTime date,
    required MPrayerTimings timings,
    required List<bool> notify,
    required dynamic settings,
    required Map<String, String> voiceIdPerPrayer,
    required String? defaultVoiceId,
    required bool bgFull,
    required bool scheduledPre,
    required DateTime now,
  }) async {
    final doy = _dayOfYear(date);
    final preMinutes = settings.preNotifyMinutes as int;
    final vibrate = settings.vibrate as bool;

    for (var i = 0; i < _salah.length; i++) {
      if (i >= notify.length || !notify[i]) continue;
      final prayer = _salah[i];
      final time = _timeFor(timings, prayer);
      if (time.isBefore(now)) continue;
      final voiceId = voiceIdPerPrayer[prayer.key] ?? defaultVoiceId;
      final channel = await _resolveChannel(voiceId, bgFull);
      final iosSound = _iosClipFor(voiceId);

      final id = _mainBandStart + doy * 10 + i;
      await _notifications.scheduleAt(
        id: id,
        when: time,
        title: 'حان الآن موعد صلاة ${_arabicName(prayer)}',
        body: 'اضغط للاستماع إلى الأذان',
        channel: channel,
        iosSound: iosSound,
        enableVibration: vibrate,
        alarm: true,
        payload: NotificationPayload(
          type: 'adhan',
          data: {'prayer': prayer.key},
        ),
      );

      if (scheduledPre && preMinutes > 0) {
        final preTime = time.subtract(Duration(minutes: preMinutes));
        if (preTime.isAfter(now)) {
          await _notifications.scheduleAt(
            id: _preBandStart + doy * 10 + i,
            when: preTime,
            title: 'اقترب موعد صلاة ${_arabicName(prayer)}',
            body: 'باقٍ $preMinutes دقيقة',
            channel: AppNotificationChannels.adhanPre,
            enableVibration: vibrate,
            payload: NotificationPayload(
              type: 'prayer',
              data: {'prayer': prayer.key},
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelWindow() async {
    final pending = await _notifications.pending();
    for (final r in pending) {
      final inMain = r.id >= _mainBandStart && r.id < _mainBandEnd;
      final inPre = r.id >= _preBandStart && r.id < _preBandEnd;
      if (inMain || inPre) await _notifications.cancel(r.id);
    }
    // Clear the legacy today-only ids (1000–1004) from the old scheduler.
    for (var id = 1000; id <= 1004; id++) {
      await _notifications.cancel(id);
    }
  }

  DateTime _timeFor(MPrayerTimings t, EPrayer p) => switch (p) {
    EPrayer.fajr => t.fajr,
    EPrayer.dhuhr => t.dhuhr,
    EPrayer.asr => t.asr,
    EPrayer.maghrib => t.maghrib,
    EPrayer.isha => t.isha,
    EPrayer.sunrise => t.sunrise,
  };

  String _arabicName(EPrayer p) => switch (p) {
    EPrayer.fajr => 'الفجر',
    EPrayer.dhuhr => 'الظهر',
    EPrayer.asr => 'العصر',
    EPrayer.maghrib => 'المغرب',
    EPrayer.isha => 'العشاء',
    EPrayer.sunrise => 'الشروق',
  };

  int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays + 1;

  /// Resolves the Android channel for [voiceId]. Creates a per-voice channel
  /// pointing at the bundled `res/raw/<voiceId>` clip (or `<voiceId>_full`
  /// when background full-adhan is on). If the raw resource is missing, Android
  /// falls back to the default sound — no crash. Null voice → shared channel.
  Future<AndroidNotificationChannel> _resolveChannel(
    String? voiceId,
    bool bgFull,
  ) async {
    if (voiceId == null || voiceId.isEmpty) {
      return AppNotificationChannels.adhan;
    }
    final raw = bgFull ? '${voiceId}_full' : voiceId;
    final channelId = bgFull ? 'adhan_${voiceId}_full' : 'adhan_$voiceId';
    await _notifications.createVoiceChannel(
      id: channelId,
      name: 'Adhan',
      rawResource: raw,
    );
    return AndroidNotificationChannel(
      channelId,
      'Adhan',
      importance: Importance.max,
      playSound: true,
    );
  }

  /// iOS per-notification sound: `<voiceId>.caf` (must be a ≤28s clip bundled
  /// in the Runner). iOS falls back to the default sound when the file isn't
  /// in the bundle, so returning the name unconditionally is safe.
  String? _iosClipFor(String? voiceId) =>
      (voiceId == null || voiceId.isEmpty) ? null : '$voiceId.caf';
}
