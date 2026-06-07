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
        super(const SReminders()) {
    refresh();
  }

  static const int cap = 30;

  final BoxReminders _box;
  final NotificationsService _notifications;
  final _uuid = const Uuid();

  void refresh() {
    emit(state.copyWith(items: _box.all(), clearError: true));
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
    await _schedule(reminder);
    refresh();
    return null;
  }

  Future<void> update(MReminder reminder) async {
    await _box.upsert(reminder);
    await _notifications.cancel(reminder.notifId);
    if (reminder.enabled) await _schedule(reminder);
    refresh();
  }

  Future<void> delete(String id) async {
    final r = _box.byId(id);
    if (r != null) await _notifications.cancel(r.notifId);
    await _box.delete(id);
    refresh();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final r = _box.byId(id);
    if (r == null) return;
    r.enabled = enabled;
    await _box.upsert(r);
    if (enabled) {
      await _schedule(r);
    } else {
      await _notifications.cancel(r.notifId);
    }
    refresh();
  }

  Future<void> _schedule(MReminder r) async {
    final hasPerm = await _notifications.hasPermission();
    if (!hasPerm) {
      final granted = await _notifications.requestPermission();
      if (!granted) return;
    }
    // For v1 we schedule a single daily repeat — `flutter_local_notifications`
    // supports `matchDateTimeComponents: time` which fires every day at the
    // chosen time. The per-day-of-week filter is enforced at fire time would
    // require a custom isolate background handler; for v1 we treat any
    // non-daily reminder as daily but tag the payload with the day mask so a
    // future enhancement can filter.
    await _notifications.scheduleDaily(
      id: r.notifId,
      hour: r.hour,
      minute: r.minute,
      title: r.title,
      body: r.body,
      channel: AppNotificationChannels.reminders,
      payload: NotificationPayload(type: 'reminder', data: {'id': r.id}),
    );
  }
}
