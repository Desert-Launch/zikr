import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_router.dart';
import 'package:quran/core/services/notifications/scheduled_alert_registry.dart';
import 'package:quran/core/utils/helper/app_alert.dart';

/// Shows a scheduled notification as an in-app banner when it fires while the
/// app is open, on whatever screen the user happens to be on.
///
/// **Why this watches a clock instead of listening for the notification.**
/// Neither platform hands a Flutter app a "your scheduled notification just
/// fired" callback — `flutter_local_notifications` only reports TAPS, and the
/// pending-notification list carries no fire times to diff against. So the app
/// mirrors its own schedule: every path that arms a notification funnels
/// through `NotificationsService._zonedSchedule`, which records what and when
/// into [ScheduledAlertRegistry]; this watcher waits for those moments.
///
/// Only ever runs in the foreground. On resume it skips whatever came due while
/// the app was away — those already arrived as real OS notifications, and
/// replaying them as a burst of banners would be noise rather than news.
class InAppNotificationWatcher with WidgetsBindingObserver {
  InAppNotificationWatcher(this._registry, this._router);

  final ScheduledAlertRegistry _registry;
  final NotificationRouter _router;

  /// Fired a beat late so a timer that wakes a hair early — rounding, or the
  /// event loop being busy — still finds its alert due rather than re-arming
  /// for the same instant and spinning.
  static const _slack = Duration(milliseconds: 300);

  Timer? _timer;
  bool _running = false;

  /// Everything up to here has already been handled (shown, or deliberately
  /// skipped). The watcher only ever looks at `(_handledUpTo, now]`.
  DateTime _handledUpTo = DateTime.now();

  /// Starts watching. Safe to call twice; the second call is a no-op.
  void start() {
    if (_running) return;
    _running = true;
    _handledUpTo = DateTime.now();
    _registry.skipTo(_handledUpTo);
    _registry.addListener(_arm);
    WidgetsBinding.instance.addObserver(this);
    _arm();
    AppLogger.info('In-app notification banners armed', tag: _tag);
  }

  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    _registry.removeListener(_arm);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.resumed) {
      _handledUpTo = DateTime.now();
      _registry.skipTo(_handledUpTo);
      _arm();
      return;
    }
    // Backgrounded: the OS owns the alert now. Drop the timer so a long-lived
    // one can't fire into a screen the user isn't looking at.
    _timer?.cancel();
    _timer = null;
  }

  /// Points a single timer at the soonest alert. Re-run on every registry
  /// change, so a freshly scheduled notification that beats the pending one
  /// takes its place.
  void _arm() {
    _timer?.cancel();
    _timer = null;
    if (!_running) return;

    final next = _registry.nextAfter(_handledUpTo);
    if (next == null) return;

    final wait = next.firesAt.difference(DateTime.now()) + _slack;
    _timer = Timer(wait.isNegative ? Duration.zero : wait, _flush);
  }

  /// Shows everything that came due, then re-arms for the next one.
  void _flush() {
    if (!_running) return;
    final now = DateTime.now();
    final since = _handledUpTo;
    // Advance BEFORE draining: taking the alerts notifies the registry, which
    // re-enters [_arm] — with the mark already moved, that pass can't rediscover
    // the very alerts being handed out here.
    _handledUpTo = now;

    for (final alert in _registry.takeDue(since, now)) {
      final payload = alert.payload;
      AppAlert.notification(
        title: alert.title,
        body: alert.body,
        payloadType: payload?.type ?? '',
        onTap: payload == null ? null : () => _router.route(payload),
      );
    }

    _arm();
  }

  static const _tag = 'InAppNotificationWatcher';
}
