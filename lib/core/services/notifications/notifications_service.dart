import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create all channels up-front (Android only; iOS uses categories).
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      for (final c in AppNotificationChannels.all) {
        await android.createNotificationChannel(c);
      }
    }

    _initialized = true;
    AppLogger.info('NotificationsService initialized',
        tag: 'NotificationsService');
  }

  /// Asks the user for the OS notification permission. Safe to call repeatedly.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Schedules a one-shot notification at [when]. If [when] is in the past,
  /// the notification is dropped silently.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    NotificationPayload? payload,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _details(channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload?.encode(),
    );
  }

  /// Schedules a daily-repeating notification at [hour]:[minute] local time.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    NotificationPayload? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      first,
      _details(channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload?.encode(),
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() async =>
      _plugin.pendingNotificationRequests();

  NotificationDetails _details(AndroidNotificationChannel channel) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: _priorityFor(channel.importance),
        playSound: channel.playSound,
        enableVibration: channel.enableVibration,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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
    final payload = NotificationPayload.fromJson(raw);
    _router.route(payload);
  }
}
