import 'package:flutter/foundation.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';

/// How a [ScheduledAlert] repeats — the registry's copy of the
/// `matchDateTimeComponents` the notification was armed with.
enum AlertRepeat { once, daily, weekly }

/// One notification this app has armed with the OS, plus the wall-clock moment
/// it is NEXT due.
///
/// The OS never tells an app "a scheduled notification just fired" — there is
/// no such callback on either platform — so the only way to mirror one in-app
/// is to remember what was scheduled and watch the clock. This is that memory.
@immutable
class ScheduledAlert {
  const ScheduledAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.firesAt,
    this.payload,
    this.repeat = AlertRepeat.once,
  });

  /// The OS scheduler id, and this entry's key in [ScheduledAlertRegistry].
  final int id;

  final String title;
  final String body;

  /// Device-local wall-clock time this alert next fires.
  final DateTime firesAt;

  /// What tapping the in-app banner should open, mirroring the tap payload on
  /// the real notification.
  final NotificationPayload? payload;

  final AlertRepeat repeat;

  /// This alert rolled forward to its first occurrence after [after], or null
  /// when it was a one-shot and has nothing left to fire.
  ///
  /// The next slot is rebuilt from the calendar rather than by adding 24h so a
  /// daily alert keeps its wall-clock time across a DST change, and it loops
  /// because the app can sit in the background across several cycles.
  ScheduledAlert? rolledForward(DateTime after) {
    if (repeat == AlertRepeat.once) return null;
    final stepDays = repeat == AlertRepeat.weekly ? 7 : 1;
    var next = firesAt;
    while (!next.isAfter(after)) {
      next = DateTime(
        next.year,
        next.month,
        next.day + stepDays,
        firesAt.hour,
        firesAt.minute,
        firesAt.second,
      );
    }
    return ScheduledAlert(
      id: id,
      title: title,
      body: body,
      firesAt: next,
      payload: payload,
      repeat: repeat,
    );
  }
}

/// In-memory mirror of every notification the app has armed with the OS, kept
/// so `InAppNotificationWatcher` knows what is due and when.
///
/// In-memory on purpose: the boot chain in `main.dart` re-arms every schedule
/// on each cold start (reminders, the azkar/quran feed, salawat, the hourly
/// zekr, the adhan window), so the registry refills itself before the user can
/// reach a screen. A schedule armed in an earlier session and never re-armed in
/// this one — a khatma daily reminder, say, until the khatma screen is opened —
/// still fires as a real OS notification; it just has no in-app twin.
class ScheduledAlertRegistry extends ChangeNotifier {
  final Map<int, ScheduledAlert> _alerts = {};

  /// Every alert currently armed, in no particular order.
  Iterable<ScheduledAlert> get alerts => _alerts.values;

  /// Records [alert], replacing any previous entry with the same id — the same
  /// overwrite the OS performs when a scheduler re-arms an existing id.
  void put(ScheduledAlert alert) {
    _alerts[alert.id] = alert;
    notifyListeners();
  }

  void remove(int id) {
    if (_alerts.remove(id) != null) notifyListeners();
  }

  void clear() {
    if (_alerts.isEmpty) return;
    _alerts.clear();
    notifyListeners();
  }

  /// The soonest alert due strictly after [after], or null when nothing is
  /// armed. Drives the watcher's timer so an idle app arms exactly one.
  ScheduledAlert? nextAfter(DateTime after) {
    ScheduledAlert? soonest;
    for (final alert in _alerts.values) {
      if (!alert.firesAt.isAfter(after)) continue;
      if (soonest == null || alert.firesAt.isBefore(soonest.firesAt)) {
        soonest = alert;
      }
    }
    return soonest;
  }

  /// Everything due in `(after, until]`, oldest first.
  ///
  /// Each returned alert is rolled forward (repeats) or dropped (one-shots) in
  /// the same pass, so one occurrence is handed out exactly once no matter how
  /// often the watcher checks.
  List<ScheduledAlert> takeDue(DateTime after, DateTime until) {
    final due = <ScheduledAlert>[];
    for (final alert in _alerts.values.toList(growable: false)) {
      if (!alert.firesAt.isAfter(after)) continue;
      if (alert.firesAt.isAfter(until)) continue;
      due.add(alert);
      _reschedule(alert, until);
    }
    if (due.isEmpty) return const [];
    due.sort((a, b) => a.firesAt.compareTo(b.firesAt));
    notifyListeners();
    return due;
  }

  /// Advances past everything already due at [moment] WITHOUT handing it out.
  ///
  /// Used when the app comes back to the foreground: those alerts fired while
  /// the user was away and were seen as real OS notifications, so replaying
  /// them as a burst of banners on resume would be noise, not news.
  void skipTo(DateTime moment) {
    var changed = false;
    for (final alert in _alerts.values.toList(growable: false)) {
      if (alert.firesAt.isAfter(moment)) continue;
      _reschedule(alert, moment);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Rolls [alert] past [moment], or forgets it when it was a one-shot. Silent
  /// — callers batch a single [notifyListeners] around a whole pass.
  void _reschedule(ScheduledAlert alert, DateTime moment) {
    final next = alert.rolledForward(moment);
    if (next == null) {
      _alerts.remove(alert.id);
    } else {
      _alerts[alert.id] = next;
    }
  }
}
