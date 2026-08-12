import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notification_router.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// App-wide notification facade. Wraps [FlutterLocalNotificationsPlugin]
/// with channel setup, permission handling, and zoned scheduling.
///
/// Higher-level handlers (PrayerNotificationHandler, AzkarHandler, etc.)
/// register their schedules via [scheduleAt]/[scheduleDaily]; this service
/// stays domain-agnostic.
class NotificationsService {
  NotificationsService(this._router);

  final NotificationRouter _router;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // CRITICAL: `tz.local` defaults to UTC until we set it. Without this every
    // scheduled notification would fire at the wrong wall-clock time (off by
    // the device's UTC offset), so they'd appear to "never arrive".
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (e) {
      // Named lookup failed (couldn't read the device zone, or the identifier
      // isn't in the tz database). Leaving `tz.local` at UTC would fire every
      // scheduled notification off by the device's offset, so derive a zone
      // whose current offset matches the device instead.
      AppLogger.error(
        'Failed to resolve local timezone by name — '
        'falling back to device UTC offset',
        tag: 'NotificationsService',
        error: e,
      );
      _setLocalTimezoneFromDeviceOffset();
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundTapHandler,
    );

    // Create all channels up-front (Android only; iOS uses categories).
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      for (final c in AppNotificationChannels.all) {
        await android.createNotificationChannel(c);
      }
      // Drop channels superseded by a re-created id (sound / audio attributes
      // can't be edited in place). Best-effort: a missing channel is a no-op.
      for (final id in AppNotificationChannels.legacyIds) {
        try {
          await android.deleteNotificationChannel(id);
        } catch (e) {
          AppLogger.warning(
            'Failed to delete legacy channel $id: $e',
            tag: 'NotificationsService',
          );
        }
      }
    }

    // Cold start: the app was launched by tapping a notification while it was
    // terminated. `onDidReceiveNotificationResponse` does NOT fire in that
    // case, so we pull the launch details and route once the first frame and
    // the Modular router are ready.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final raw = launch?.notificationResponse?.payload;
      if (raw != null) _routeDeferred(NotificationPayload.fromJson(raw));
    }

    _initialized = true;
    AppLogger.info(
      'NotificationsService initialized',
      tag: 'NotificationsService',
    );
  }

  /// Picks a timezone whose *current* offset matches the device and makes it
  /// `tz.local`. Not DST-history-accurate, but correct for the near-term
  /// scheduling window — far better than leaving `tz.local` at UTC (which
  /// would shift every adhan by the device's offset). Falls back to UTC only
  /// if no zone matches (shouldn't happen).
  void _setLocalTimezoneFromDeviceOffset() {
    final offset = DateTime.now().timeZoneOffset;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  /// Asks the user for the OS notification permission. Safe to call repeatedly.
  ///
  /// Covers POST_NOTIFICATIONS (Android 13+) / iOS alert+sound+badge via
  /// permission_handler, then ensures exact-alarm scheduling is permitted on
  /// Android 12+ (separate grant from notifications).
  Future<bool> requestPermission() async {
    // iOS: ask UNUserNotificationCenter directly via the plugin. This both
    // shows the native prompt (when status is undetermined) AND registers the
    // app, so a "Notifications" section appears under Settings — which doesn't
    // happen if we only go through permission_handler.
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android: POST_NOTIFICATIONS (13+) plus the separate exact-alarm grant (12+).
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      final canExact = await android.canScheduleExactNotifications() ?? true;
      if (!canExact) await android.requestExactAlarmsPermission();
      return granted;
    }

    // Other platforms: fall back to permission_handler.
    return (await Permission.notification.request()).isGranted;
  }

  /// Reads the live notification permission through the SAME plugin that
  /// [requestPermission] grants through (flutter_local_notifications), so the
  /// two never disagree. Querying permission_handler here instead would read a
  /// different source of truth: a fresh grant via the plugin can still report
  /// `false` through permission_handler, which made scheduleTest() skip with a
  /// "no permission" warning right after the user allowed notifications.
  Future<bool> hasPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    // Other platforms: fall back to permission_handler.
    return Permission.notification.isGranted;
  }

  /// Schedules a one-shot notification at [when]. If [when] is in the past,
  /// the notification is dropped silently.
  ///
  /// [iosSound] is a per-notification iOS sound file bundled in the app
  /// (≤30s, e.g. `adhan_egypt.caf`) — per-notification sound works on iOS,
  /// unlike Android where the sound is fixed to the channel. [alarm] raises
  /// the Android category + full-screen intent for adhan-style alerts.
  ///
  /// Returns whether the OS accepted the alarm — see [_zonedSchedule].
  Future<bool> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    NotificationPayload? payload,
    String? iosSound,
    bool? enableVibration,
    bool alarm = false,
  }) async {
    if (when.isBefore(DateTime.now())) return false;
    return _zonedSchedule(
      id: id,
      title: title,
      body: body,
      when: tz.TZDateTime.from(when, tz.local),
      details: _details(
        channel,
        iosSound: iosSound,
        enableVibrationOverride: enableVibration,
        alarm: alarm,
      ),
      payload: payload?.encode(),
    );
  }

  /// The single `zonedSchedule` chokepoint. Every scheduling path funnels
  /// through it so one rejected alarm can never abort the loop that was
  /// registering the rest.
  ///
  /// Two failure modes are handled explicitly:
  ///
  ///  * **`exact_alarms_not_permitted`** — Android 12/13 let the user revoke
  ///    "Alarms & reminders". Retried as an inexact alarm so the reminder still
  ///    arrives (a few minutes late) instead of vanishing.
  ///  * **anything else** (the per-app 500 alarm cap, an OEM rejection) — logged
  ///    and swallowed. Previously the exception propagated out of the caller's
  ///    `for` loop, so a single bad slot silently cost every notification queued
  ///    after it, and — from `main`'s un-caught boot chain — the adhan window
  ///    and the whole azkar/salawat/hourly reconciliation too.
  Future<bool> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    Future<void> attempt(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );

    try {
      await attempt(AndroidScheduleMode.exactAllowWhileIdle);
      return true;
    } on PlatformException catch (e, st) {
      if (e.code == 'exact_alarms_not_permitted') {
        try {
          await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
          AppLogger.warning(
            'Exact alarms not permitted — notification $id scheduled inexactly '
            '(it may arrive a few minutes late)',
            tag: 'NotificationsService',
          );
          return true;
        } catch (e2, st2) {
          AppLogger.error(
            'Inexact fallback failed for notification $id',
            tag: 'NotificationsService',
            error: e2,
            stackTrace: st2,
          );
          return false;
        }
      }
      AppLogger.error(
        'Failed to schedule notification $id (${e.code})',
        tag: 'NotificationsService',
        error: e,
        stackTrace: st,
      );
      return false;
    } catch (e, st) {
      AppLogger.error(
        'Failed to schedule notification $id',
        tag: 'NotificationsService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Creates (or updates) an Android channel whose sound is a bundled
  /// `res/raw/<rawResource>` clip — used to give a selected adhan voice its
  /// own notification sound. No-op on non-Android. Channel sound is immutable
  /// once created, so each distinct clip needs its own stable [id].
  ///
  /// If the raw resource is missing from the build, Android falls back to the
  /// default sound rather than failing — safe to call before clips ship.
  Future<void> createVoiceChannel({
    required String id,
    required String name,
    required String rawResource,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        id,
        name,
        description: 'Adhan alert with the selected voice',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(rawResource),
        // Alarm stream, not the notification one — the adhan follows the
        // device's alarm volume like the native full-adhan service does.
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  /// Removes a channel by id. Used to retire a channel whose sound or audio
  /// attributes changed (both immutable after creation, so the replacement
  /// needs a new id). Safe when the channel doesn't exist.
  Future<void> deleteChannel(String id) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    try {
      await android.deleteNotificationChannel(id);
    } catch (e) {
      AppLogger.warning(
        'Failed to delete channel $id: $e',
        tag: 'NotificationsService',
      );
    }
  }

  /// Schedules a daily-repeating notification at [hour]:[minute] local time.
  ///
  /// [iosSound] is a per-notification iOS sound file bundled in the app
  /// (≤30s, e.g. `salah_3la_mohamed.caf`); Android sound is fixed to the
  /// [channel] instead.
  Future<bool> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    NotificationPayload? payload,
    String? iosSound,
  }) {
    return _zonedSchedule(
      id: id,
      title: title,
      body: body,
      when: _nextInstanceOfTime(hour, minute),
      details: _details(channel, iosSound: iosSound),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload?.encode(),
    );
  }

  /// Schedules a weekly-repeating notification on [weekday]
  /// (DateTime.monday..sunday → 1..7) at [hour]:[minute] local time.
  Future<bool> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    NotificationPayload? payload,
  }) {
    return _zonedSchedule(
      id: id,
      title: title,
      body: body,
      when: _nextInstanceOfWeekday(weekday, hour, minute),
      details: _details(channel),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload?.encode(),
    );
  }

  /// The next future [hour]:[minute] in local time (today, or tomorrow if the
  /// time already passed).
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// The next future occurrence of [weekday] at [hour]:[minute] local time.
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Shows (or updates in place) an ongoing progress notification — used for
  /// long-running downloads. Reusing the same [id] replaces the previous one
  /// rather than stacking. [onlyAlertOnce] + the low-importance `downloads`
  /// channel keep rapid progress updates silent. Pass a non-positive
  /// [maxProgress] for an indeterminate spinner. No-op-safe if permission was
  /// never granted (the OS simply drops it).
  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required String body,
    required int maxProgress,
    required int progress,
  }) async {
    final indeterminate = maxProgress <= 0;
    final clamped = indeterminate ? 0 : progress.clamp(0, maxProgress).toInt();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppNotificationChannels.downloads.id,
        AppNotificationChannels.downloads.name,
        channelDescription: AppNotificationChannels.downloads.description,
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        showProgress: true,
        maxProgress: indeterminate ? 0 : maxProgress,
        progress: clamped,
        indeterminate: indeterminate,
        category: AndroidNotificationCategory.progress,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() async =>
      _plugin.pendingNotificationRequests();

  NotificationDetails _details(
    AndroidNotificationChannel channel, {
    String? iosSound,
    bool? enableVibrationOverride,
    bool alarm = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: _priorityFor(channel.importance),
        playSound: channel.playSound,
        sound: channel.sound,
        enableVibration: enableVibrationOverride ?? channel.enableVibration,
        category: alarm ? AndroidNotificationCategory.alarm : null,
        fullScreenIntent: alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: iosSound,
      ),
    );
  }

  Priority _priorityFor(Importance i) {
    switch (i) {
      case Importance.max:
      case Importance.high:
        return Priority.high;
      case Importance.defaultImportance:
        return Priority.defaultPriority;
      case Importance.low:
      case Importance.min:
      case Importance.none:
      case Importance.unspecified:
        return Priority.low;
    }
  }

  void _onTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null) return;
    _routeDeferred(NotificationPayload.fromJson(raw));
  }

  /// Routes after the current frame so the Modular router/navigator is ready —
  /// important on cold start, where the tap arrives before the first build.
  void _routeDeferred(NotificationPayload payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _router.route(payload));
  }
}

/// Background-isolate tap handler. Runs without a Flutter UI, so it cannot
/// navigate; plain taps are routed on resume (`_onTap`) or cold start
/// (`getNotificationAppLaunchDetails`). Reserved for future notification
/// action buttons that need to do work in the background. Must be a top-level
/// function with the entry-point pragma so the engine can find it.
@pragma('vm:entry-point')
void notificationBackgroundTapHandler(NotificationResponse response) {}
