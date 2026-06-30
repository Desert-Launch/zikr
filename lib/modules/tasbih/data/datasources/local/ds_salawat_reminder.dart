import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';

/// Schedules the "salawat upon the Prophet ﷺ" reminders. Two modes:
///
///  * **Interval** — fires every `intervalHours` from 08:30 to 22:30. The
///    minute is fixed to 30 so it never collides with the on-the-hour
///    [AppNotificationChannels.hourly] tasbih (which fires at minute 0).
///  * **Specific time** — a single daily reminder at the user's chosen
///    `hour:minute`.
///
/// Each reminder plays the bundled salawat clip via
/// [AppNotificationChannels.salawat] (Android) / [_iosSound] (iOS).
///
/// Notification IDs reserved: 5099 (specific time) + 5108..5122 (one per
/// active hour) — clear of the hourly tasbih block (5000..5014).
class DSSalawatReminder {
  DSSalawatReminder(this._notifications);

  final NotificationsService _notifications;

  /// iOS notification sound — the CAF copy of `salah_3la_mohamed.mp3` bundled
  /// in `ios/Runner/Sounds/`.
  static const _iosSound = 'salah_3la_mohamed.caf';

  /// Fixed reminder minute. Offset from the hourly tasbih's minute 0.
  static const _intervalMinute = 30;

  /// Reminder window (inclusive), at minute [_intervalMinute].
  static const _startHour = 8;
  static const _endHour = 22;

  /// ID for the single specific-time reminder.
  static const _specificId = 5099;

  /// Base for the per-hour interval reminders (id = [_hourBase] + hour).
  static const _hourBase = 5100;

  /// Applies the current reminder configuration: clears any existing schedule,
  /// then (re)schedules according to [enabled] / [intervalHours].
  ///
  /// [intervalHours] of `0` selects specific-time mode ([hour]:[minute]);
  /// any positive value selects interval mode (the explicit time is ignored).
  Future<void> apply({
    required bool enabled,
    required int intervalHours,
    required int hour,
    required int minute,
  }) async {
    await disable();
    if (!enabled) return;

    if (intervalHours <= 0) {
      await _scheduleOne(_specificId, hour, minute);
      return;
    }

    for (var h = _startHour; h <= _endHour; h += intervalHours) {
      await _scheduleOne(_hourBase + h, h, _intervalMinute);
    }
  }

  Future<void> _scheduleOne(int id, int hour, int minute) async {
    await _notifications.scheduleDaily(
      id: id,
      hour: hour,
      minute: minute,
      title: 'الصلاة على النبي ﷺ',
      body: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      channel: AppNotificationChannels.salawat,
      iosSound: _iosSound,
      payload: const NotificationPayload(type: 'salawat'),
    );
  }

  /// Cancels every reminder this source may have scheduled.
  Future<void> disable() async {
    await _notifications.cancel(_specificId);
    for (var h = _startHour; h <= _endHour; h++) {
      await _notifications.cancel(_hourBase + h);
    }
  }
}
