import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';
import 'package:quran/modules/reminders/data/sources/local/box_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/s_reminders.dart';
import 'package:uuid/uuid.dart';

/// Manages the user's custom reminders. Enforces the 30-item cap (Decision 4)
/// and re-schedules each item's daily notification when its time/days change.
class CBReminders extends Cubit<SReminders> {
  CBReminders({
    required BoxReminders box,
    required NotificationsService notifications,
  })  : _box = box,
        _notifications = notifications,
        super(SReminders()) {
    refresh();
  }

  static const int cap = 30;

  final BoxReminders _box;
  final NotificationsService _notifications;
  final _uuid = const Uuid();

  void refresh() => _refreshWith(null);

  /// Re-reads the box and republishes [error] (null clears it).
  ///
  /// [refresh] on its own always clears the error, which used to wipe the
  /// failure [_schedule] had *just* emitted — so a reminder that could not be
  /// scheduled (permission revoked, alarm rejected) was persisted, listed, and
  /// reported as a success while never being able to fire.
  void _refreshWith(String? error) {
    emit(
      state.copyWith(
        items: _box.all(),
        error: error,
        clearError: error == null,
      ),
    );
  }

  void clearError() => emit(state.copyWith(clearError: true));

  /// Re-registers every enabled reminder's notifications. Called on app start so
  /// schedules self-heal after a reboot, timezone change, or OS cleanup. No-op
  /// (and no prompt) when notifications aren't yet permitted.
  Future<void> rescheduleAll() async {
    if (!await _notifications.hasPermission()) return;
    for (final r in _box.all()) {
      await _cancel(r);
      if (r.enabled) await _schedule(r);
    }
  }

  /// Creates a new reminder. Returns null on success, error message on
  /// failure (e.g., at-cap).
  Future<String?> create({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<bool> daysOfWeek,
    int iconId = 2,
    int colorId = 3,
  }) async {
    if (_box.count >= cap) {
      emit(state.copyWith(error: 'reminders_max_reached'));
      return 'reminders_max_reached';
    }
    final reminder = MReminder(
      id: _uuid.v4(),
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      daysOfWeek: List<bool>.from(daysOfWeek),
      iconId: iconId,
      colorId: colorId,
    );
    await _box.upsert(reminder);
    final error = await _schedule(reminder);
    _refreshWith(error);
    return error;
  }

  Future<void> update(MReminder reminder) async {
    await _box.upsert(reminder);
    await _cancel(reminder);
    final error = reminder.enabled ? await _schedule(reminder) : null;
    _refreshWith(error);
  }

  Future<void> delete(String id) async {
    final r = _box.byId(id);
    if (r != null) await _cancel(r);
    await _box.delete(id);
    refresh();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final r = _box.byId(id);
    if (r == null) return;
    r.enabled = enabled;
    await _box.upsert(r);
    String? error;
    if (enabled) {
      error = await _schedule(r);
    } else {
      await _cancel(r);
    }
    _refreshWith(error);
  }

  /// Cancels every notification id the reminder could own (daily + each
  /// weekday), so a stale alarm can't survive a day-mask or time change.
  Future<void> _cancel(MReminder r) async {
    for (final id in r.allNotifIds) {
      await _notifications.cancel(id);
    }
  }

  /// Registers [r]'s notifications. Returns null on success, or the i18n key of
  /// the reason it could not be scheduled — the caller surfaces it instead of
  /// leaving the user with a reminder that looks saved but can never fire.
  Future<String?> _schedule(MReminder r) async {
    if (!await _ensurePermission()) return 'reminders_permission_denied';

    final payload = NotificationPayload(type: 'reminder', data: {'id': r.id});
    if (r.isDaily) {
      // All seven days selected → a single daily repeat (fires every day).
      final ok = await _notifications.scheduleDaily(
        id: r.notifId,
        hour: r.hour,
        minute: r.minute,
        title: r.title,
        body: r.body,
        channel: AppNotificationChannels.reminders,
        payload: payload,
      );
      return ok ? null : 'reminders_schedule_failed';
    }
    // Otherwise one weekly-repeating alarm per selected weekday.
    var allOk = true;
    for (final weekday in r.scheduledWeekdays) {
      final ok = await _notifications.scheduleWeekly(
        id: r.weeklyNotifId(weekday),
        weekday: weekday,
        hour: r.hour,
        minute: r.minute,
        title: r.title,
        body: r.body,
        channel: AppNotificationChannels.reminders,
        payload: payload,
      );
      allOk = allOk && ok;
    }
    return allOk ? null : 'reminders_schedule_failed';
  }

  Future<bool> _ensurePermission() async {
    if (await _notifications.hasPermission()) return true;
    return _notifications.requestPermission();
  }
}
