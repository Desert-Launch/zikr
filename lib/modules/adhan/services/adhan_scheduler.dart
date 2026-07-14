import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/init/init_notifications_service.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_audio_alarms.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_times.dart';
import 'package:quran/modules/prayer/utils/prayer_method_mapper.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';

/// Orchestrates prayer-time → adhan-notification scheduling. [reschedule]
/// builds the current week (Saturday–Friday) plus the next week as a buffer,
/// so the schedule survives until the next weekly refresh. Call it on app
/// launch, after a settings change, and after the location/timezone changes.
///
/// iOS hard-caps pending notifications at 64 across the whole app, so the
/// window is trimmed to [_iosBudget] there; Android has no such cap.
/// Re-running [reschedule] overwrites cleanly because notification ids are
/// deterministic (day-of-year derived).
class AdhanScheduler {
  AdhanScheduler({
    required NotificationsService notifications,
    required DSLocation location,
    required UCGetPrayerTimes getTimes,
    required BoxPrayerSettings prayerSettings,
    required BoxAdhanSettings adhanSettings,
    required BoxAdhanPreference adhanPrefs,
    required DSLocalAdhan local,
    required DSLastLocation lastLocation,
    required AdhanAudioAlarms audioAlarms,
    required InitNotificationsService initNotifications,
    required DSHourlyTasbih hourlyZekr,
  }) : _notifications = notifications,
       _location = location,
       _getTimes = getTimes,
       _prayerSettings = prayerSettings,
       _adhanSettings = adhanSettings,
       _adhanPrefs = adhanPrefs,
       _local = local,
       _lastLocation = lastLocation,
       _audioAlarms = audioAlarms,
       _initNotifications = initNotifications,
       _hourlyZekr = hourlyZekr;

  final NotificationsService _notifications;
  final DSLocation _location;
  final UCGetPrayerTimes _getTimes;
  final BoxPrayerSettings _prayerSettings;
  final BoxAdhanSettings _adhanSettings;
  final BoxAdhanPreference _adhanPrefs;
  final DSLocalAdhan _local;
  final DSLastLocation _lastLocation;
  final AdhanAudioAlarms _audioAlarms;
  final InitNotificationsService _initNotifications;
  final DSHourlyTasbih _hourlyZekr;

  static const int _preWindowDays = 4; // pre-reminders only for the near days

  /// Days of full-adhan native audio alarms armed ahead (Android background
  /// mode). Re-armed on every app open + after reboot, so a small rolling
  /// window is plenty; days beyond it still get the short-clip notification.
  static const int _audioWindowDays = 3;

  /// Adhan's slice of iOS's 64 pending-notification budget (the rest is left
  /// for reminders/azkar/etc.). Ignored on Android.
  static const int _iosBudget = 56;

  /// Notifications still allowed in the current [reschedule] run (iOS budget).
  int _remaining = 0;

  /// One-shot test notification id. Deliberately outside the main/pre bands so
  /// [_cancelWindow] (and a real reschedule) never clobbers a pending test.
  static const int _testId = 999999;

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

  /// Debug-only registry of `notification id → resolved fire time`, populated
  /// as the window is (re)built. The OS pending list doesn't expose the fire
  /// time, so this is the only place the concrete date/time is known. Reflects
  /// the most recent [reschedule]/[scheduleTest] in this app session.
  final Map<int, DateTime> _scheduledTimes = {};

  /// Read-only view of the scheduled fire times (see [_scheduledTimes]).
  Map<int, DateTime> get scheduledTimes => Map.unmodifiable(_scheduledTimes);

  /// Cancels the current adhan window and rebuilds it from prayer times.
  /// Safe to call repeatedly; concurrent calls are coalesced.
  ///
  /// [useCachedLocation] skips the live GPS fix and uses the last-known
  /// location instead — required from the weekly background isolate, which
  /// can't acquire a fresh fix. The foreground path persists each fresh fix so
  /// the background path has something to read.
  /// [armAudioAlarms] arms the native full-adhan audio alarms (Android
  /// background auto-play). Only the UI isolate can reach the native channel,
  /// so the weekly background isolate passes `false` and relies on the alarms
  /// the UI isolate / boot receiver already armed.
  Future<void> reschedule({
    bool useCachedLocation = false,
    bool armAudioAlarms = true,
  }) async {
    if (_running) return;
    _running = true;
    try {
      await _cancelWindow();
      // Clear previously-armed native alarms before rebuilding. Also clears them
      // when the master switch / full-adhan mode is off (handled by the early
      // returns / mode check below never re-arming).
      if (armAudioAlarms) await _audioAlarms.cancelAll();

      final settings = _adhanSettings.current();
      if (!settings.enabled) {
        AppLogger.info(
          'Adhan disabled — window cleared',
          tag: 'AdhanScheduler',
        );
        return;
      }

      if (!await _notifications.hasPermission()) {
        AppLogger.warning(
          'No notification permission — adhan scheduling skipped (0 queued)',
          tag: 'AdhanScheduler',
        );
        return;
      }

      LocationResult? loc;
      if (useCachedLocation) {
        loc = _lastLocation.read();
      } else {
        try {
          loc = await _location.currentPosition();
          if (loc != null) await _lastLocation.write(loc);
        } catch (e) {
          AppLogger.warning(
            'Adhan scheduling: live location failed ($e) — using cached',
            tag: 'AdhanScheduler',
          );
          loc = _lastLocation.read();
        }
      }
      if (loc == null) {
        AppLogger.warning(
          'Adhan scheduling: no location available — skipped (0 queued)',
          tag: 'AdhanScheduler',
        );
        return;
      }

      final prayer = _prayerSettings.current();
      final notify = prayer.notifyForPrayer;
      final method = PrayerMethodMapper.methodForCountry(loc.countryCode);
      final pref = _adhanPrefs.current();

      // Android background full-adhan: when on, the near-window prayers get a
      // SILENT notification + a native alarm that plays the full adhan via the
      // foreground service. Days beyond the audio window (and all non-Android /
      // mode-off cases) fall back to the short-clip notification. iOS always
      // uses the short .caf (Apple's 30s cap) — no native audio is possible.
      final fullAndroid =
          Platform.isAndroid &&
          settings.androidBackgroundFullAdhan &&
          settings.playbackMode == MAdhanSettings.playbackFull;

      // Effective Fajr voice (a per-prayer override still wins per day below).
      String? fajrVoiceId;
      if (pref.useFajrSpecific) {
        final explicit = pref.fajrAdhanId;
        fajrVoiceId = (explicit != null && explicit.isNotEmpty)
            ? explicit
            : (await _local.fajrDefault()).id;
      }

      // Window: today → end of next week (weeks run Saturday–Friday), trimmed
      // to the iOS budget; Android schedules the whole window. Pure integer
      // day-counting keeps the horizon DST-safe.
      final now = DateTime.now();
      final daysIntoWeek = (now.weekday - DateTime.saturday) % 7; // 0 = Saturday
      final totalDays = 14 - daysIntoWeek; // 8..14
      _remaining = Platform.isIOS ? _iosBudget : 1 << 30;

      // Today's prayer times, captured for the companion-notification
      // reconciliation (azkar re-timing + hourly-zekr conflict avoidance).
      MPrayerTimings? todayTimings;

      for (var dayOffset = 0; dayOffset < totalDays; dayOffset++) {
        if (_remaining <= 0) break;
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
        if (dayOffset == 0) todayTimings = timings;

        await _scheduleDay(
          date: date,
          timings: timings,
          notify: notify,
          settings: settings,
          voiceIdPerPrayer: prayer.adhanIdPerPrayer ?? const {},
          preNotifyPerPrayer: prayer.preNotifyMinutesPerPrayer ?? const {},
          defaultVoiceId: pref.defaultAdhanId,
          fajrVoiceId: fajrVoiceId,
          fullAndroid: fullAndroid,
          armAudioAlarms: armAudioAlarms,
          dayOffset: dayOffset,
          scheduledPre: dayOffset < _preWindowDays,
          now: now,
        );
      }

      // Diagnostic: surface how many adhan notifications are actually queued
      // after a rebuild. A 0 here (with permission + location present) points
      // at prayer-time fetches failing; a healthy run shows tens of pending.
      final pending = await _notifications.pending();
      final adhanPending = pending
          .where(
            (r) =>
                (r.id >= _mainBandStart && r.id < _mainBandEnd) ||
                (r.id >= _preBandStart && r.id < _preBandEnd),
          )
          .length;
      AppLogger.info(
        'Adhan window rebuilt — $adhanPending adhan notifications pending '
        '(app total: ${pending.length})',
        tag: 'AdhanScheduler',
      );

      // Re-time the azkar to today's prayer times and reschedule the hourly
      // zekr around the now-known prayer/azkar slots. UI-isolate only — the
      // weekly background isolate (armAudioAlarms=false) may not have the
      // companion Hive boxes open, and the UI isolate redoes this on next open.
      if (armAudioAlarms && todayTimings != null) {
        await _reconcileCompanionNotifications(todayTimings);
      }
    } finally {
      _running = false;
    }
  }

  /// Keeps the azkar and hourly-zekr feeds in sync with live prayer times:
  ///   1. morning azkar → Fajr+1h, evening azkar → Maghrib−15m;
  ///   2. reschedule the hourly zekr so no slot fires within 10 minutes of a
  ///      prayer or azkar/quran notification in the same hour.
  /// Failures here never break the adhan schedule (best-effort companion work).
  Future<void> _reconcileCompanionNotifications(MPrayerTimings timings) async {
    try {
      await _initNotifications.updateAzkarNotifications(
        fajrTime: timings.fajr,
        maghribTime: timings.maghrib,
      );

      final reserved = <DateTime>[
        timings.fajr,
        timings.dhuhr,
        timings.asr,
        timings.maghrib,
        timings.isha,
        ..._initNotifications.occupiedTimesToday(),
      ];
      await _hourlyZekr.rescheduleWithReservedTimes(reserved);
    } catch (e, st) {
      AppLogger.error(
        'Companion notification reconciliation failed',
        tag: 'AdhanScheduler',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Cancels every adhan notification so a disabled master switch leaves
  /// nothing pending.
  Future<void> cancelAll() => _cancelWindow();

  /// Schedules a single test adhan [after] from now (default 1 minute),
  /// routed through the EXACT same channel/sound/alarm path a real prayer
  /// uses. This isolates the notification pipeline (permission, exact-alarm
  /// delivery, timezone, the selected voice's sound) from the location /
  /// prayer-time fetch chain — if the test fires but real adhans don't, the
  /// problem is location or prayer-time fetching, not notifications.
  ///
  /// Returns the fire time, or null if notification permission isn't granted
  /// (the caller should prompt). Uses the default voice and a dedicated
  /// [_testId] outside the scheduling bands, so it never disturbs the real
  /// window and a real reschedule never cancels it.
  Future<DateTime?> scheduleTest({
    Duration after = const Duration(minutes: 1),
  }) async {
    if (!await _notifications.hasPermission()) {
      AppLogger.warning(
        'Test adhan skipped — no notification permission',
        tag: 'AdhanScheduler',
      );
      return null;
    }

    final settings = _adhanSettings.current();
    final pref = _adhanPrefs.current();
    final voiceId = pref.defaultAdhanId;

    final fullAndroid =
        Platform.isAndroid &&
        settings.androidBackgroundFullAdhan &&
        settings.playbackMode == MAdhanSettings.playbackFull;
    final useFullAdhan =
        fullAndroid && voiceId != null && voiceId.isNotEmpty;

    final channel = useFullAdhan
        ? AppNotificationChannels.adhanSilent
        : await _resolveChannel(voiceId);
    final iosSound = _iosClipFor(voiceId);

    final when = DateTime.now().add(after);
    await _notifications.scheduleAt(
      id: _testId,
      when: when,
      title: 'adhan_test_notif_title'.tr(),
      body: 'adhan_test_notif_body'.tr(),
      channel: channel,
      iosSound: iosSound,
      enableVibration: settings.vibrate,
      alarm: !useFullAdhan,
      payload: const NotificationPayload(
        type: 'adhan',
        data: {'prayer': 'dhuhr'},
      ),
    );
    _scheduledTimes[_testId] = when;

    if (useFullAdhan) {
      await _audioAlarms.schedule(
        id: _testId,
        when: when,
        rawRes: '${voiceId}_full',
        title: 'adhan_playing_title'.tr(),
        body: 'adhan_test_notif_title'.tr(),
        stopLabel: 'adhan_stop'.tr(),
      );
    }

    AppLogger.info(
      'Test adhan scheduled at $when (voice: ${voiceId ?? 'default'}, '
      'full: $useFullAdhan)',
      tag: 'AdhanScheduler',
    );
    return when;
  }

  Future<void> _scheduleDay({
    required DateTime date,
    required MPrayerTimings timings,
    required List<bool> notify,
    required dynamic settings,
    required Map<String, String> voiceIdPerPrayer,
    required Map<String, int> preNotifyPerPrayer,
    required String? defaultVoiceId,
    required String? fajrVoiceId,
    required bool fullAndroid,
    required bool armAudioAlarms,
    required int dayOffset,
    required bool scheduledPre,
    required DateTime now,
  }) async {
    final doy = _dayOfYear(date);
    final vibrate = settings.vibrate as bool;

    for (var i = 0; i < _salah.length; i++) {
      if (_remaining <= 0) return;
      if (i >= notify.length || !notify[i]) continue;
      final prayer = _salah[i];
      final time = _timeFor(timings, prayer);
      if (time.isBefore(now)) continue;
      final voiceId = _voiceForPrayer(
        prayer,
        voiceIdPerPrayer,
        defaultVoiceId,
        fajrVoiceId,
      );

      // Full-adhan native playback applies to near-window prayers with a known
      // voice. The notification then goes silent (the foreground service plays
      // the audio); the silencing is independent of whether we can arm the
      // alarm here, so the weekly background isolate doesn't re-sound prayers
      // the UI isolate already armed natively.
      final useFullAdhan =
          fullAndroid &&
          voiceId != null &&
          voiceId.isNotEmpty &&
          dayOffset < _audioWindowDays;

      final channel = useFullAdhan
          ? AppNotificationChannels.adhanSilent
          : await _resolveChannel(voiceId);
      final iosSound = _iosClipFor(voiceId);

      final id = _mainBandStart + doy * 10 + i;
      final prayerName = 'prayer_${prayer.key}'.tr();
      await _notifications.scheduleAt(
        id: id,
        when: time,
        title: 'adhan_notif_title'.tr().replaceFirst('{{prayer}}', prayerName),
        body: 'adhan_notif_body'.tr(),
        channel: channel,
        iosSound: iosSound,
        enableVibration: vibrate,
        // A silent full-adhan companion shouldn't raise a full-screen alarm
        // intent; the service's own notification carries the Stop control.
        alarm: !useFullAdhan,
        payload: NotificationPayload(
          type: 'adhan',
          data: {'prayer': prayer.key},
        ),
      );
      _scheduledTimes[id] = time;

      if (useFullAdhan && armAudioAlarms) {
        await _audioAlarms.schedule(
          id: id,
          when: time,
          rawRes: '${voiceId}_full',
          title: 'adhan_playing_title'.tr(),
          body: 'adhan_notif_title'.tr().replaceFirst('{{prayer}}', prayerName),
          stopLabel: 'adhan_stop'.tr(),
        );
      }
      _remaining--;

      final preMinutes = preNotifyPerPrayer[prayer.key] ?? 0;
      if (scheduledPre && preMinutes > 0 && _remaining > 0) {
        final preTime = time.subtract(Duration(minutes: preMinutes));
        final preId = _preBandStart + doy * 10 + i;
        if (preTime.isAfter(now)) {
          await _notifications.scheduleAt(
            id: preId,
            when: preTime,
            title: 'adhan_notif_pre_title'.tr().replaceFirst(
              '{{prayer}}',
              prayerName,
            ),
            body: 'adhan_notif_pre_body'.tr().replaceFirst(
              '{{m}}',
              '$preMinutes',
            ),
            channel: AppNotificationChannels.adhanPre,
            enableVibration: vibrate,
            payload: NotificationPayload(
              type: 'prayer',
              data: {'prayer': prayer.key},
            ),
          );
          _scheduledTimes[preId] = preTime;
          _remaining--;
        }
      }
    }
  }

  /// Per-prayer voice: an explicit per-prayer override wins; otherwise Fajr
  /// uses the Fajr-specific voice (when enabled) and every other prayer falls
  /// back to the default. Mirrors `CBAdhanPlayer.adhanForPrayer` so the
  /// notification sound matches the in-app playback.
  String? _voiceForPrayer(
    EPrayer prayer,
    Map<String, String> perPrayer,
    String? defaultVoiceId,
    String? fajrVoiceId,
  ) {
    final override = perPrayer[prayer.key];
    if (override != null && override.isNotEmpty) return override;
    if (prayer == EPrayer.fajr && fajrVoiceId != null) return fajrVoiceId;
    return defaultVoiceId;
  }

  Future<void> _cancelWindow() async {
    final pending = await _notifications.pending();
    for (final r in pending) {
      final inMain = r.id >= _mainBandStart && r.id < _mainBandEnd;
      final inPre = r.id >= _preBandStart && r.id < _preBandEnd;
      if (inMain || inPre) await _notifications.cancel(r.id);
    }
    // Drop stale window entries from the debug registry (the test id lives
    // outside these bands, so it survives).
    _scheduledTimes.removeWhere(
      (id, _) =>
          (id >= _mainBandStart && id < _mainBandEnd) ||
          (id >= _preBandStart && id < _preBandEnd),
    );
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

  int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays + 1;

  /// Resolves the Android channel for [voiceId]'s SHORT notification clip
  /// (`res/raw/<voiceId>`, the 28s alert). The full adhan is never a channel
  /// sound — Android truncates long channel sounds, so multi-minute playback is
  /// handled by the native foreground service instead. If the raw resource is
  /// missing, Android falls back to the default sound — no crash. Null voice →
  /// shared channel.
  Future<AndroidNotificationChannel> _resolveChannel(String? voiceId) async {
    if (voiceId == null || voiceId.isEmpty) {
      return AppNotificationChannels.adhan;
    }
    final channelId = 'adhan_$voiceId';
    await _notifications.createVoiceChannel(
      id: channelId,
      name: 'Adhan',
      rawResource: voiceId,
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
