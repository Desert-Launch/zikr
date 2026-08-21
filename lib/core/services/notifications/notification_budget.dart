/// iOS's per-app cap on *pending* notification requests, and how this app
/// divides it up.
///
/// iOS keeps at most [iosPendingCap] pending requests per app and drops every
/// `add` past that **silently** — no exception, no error code, the request
/// simply never appears in the pending list. So a feed that arms itself when
/// the queue is already full is not "late", it is permanently dead: the next
/// launch cancels an id that was never queued (a no-op that frees nothing) and
/// the re-add is dropped again.
///
/// That is exactly how the khatma wird reminder was lost. Every repeating feed
/// below occupies its slot for good, and the adhan window — the one elastic
/// consumer, since it is just a horizon that gets re-armed on every app open —
/// was sized so the total came to 66. The last few things armed lost, and the
/// wird reminder (armed once, from a screen, with no boot-chain retry that
/// could ever win) never came back.
///
/// **Adding a new scheduled feed means adding it here**, not just scheduling
/// it: the reserves are what keeps [adhanWindow] from swallowing the queue.
/// Android has no equivalent cap (its limit is 500 *alarms* per uid), so none
/// of this applies there — see `AdhanScheduler.reschedule`, which only
/// consults the budget on iOS.
class NotificationBudget {
  NotificationBudget._();

  /// Apple's hard limit on pending requests per app.
  static const int iosPendingCap = 64;

  /// Hourly zekr — one repeating request per hour of the reminder window
  /// (`BoxAppSettings.reminderWindow`, 08:00–22:00 by default). Default ON.
  static const int hourlyZikr = 15;

  /// Azkar + Quran feed (`init_notifications.json`) — see [NotificationIds].
  static const int initFeed = 6;

  /// Salawat reminders — interval mode across the reminder window, every 3h by
  /// default. Default ON.
  static const int salawat = 5;

  /// The khatma daily wird reminder (`CBKhatma`) — a single daily repeat.
  static const int khatmaWird = 1;

  /// Headroom for the user's own reminders (`CBReminders`), which are
  /// unbounded: a weekly reminder takes one id per selected weekday. Not a
  /// limit on them — they are armed before the adhan window and simply take
  /// what they need; this only stops the adhan from planning to use it.
  static const int userReminders = 5;

  /// Slots the fixed feeds hold permanently.
  static const int reserved =
      hourlyZikr + initFeed + salawat + khatmaWird + userReminders;

  /// What the adhan window may claim on iOS: everything the other feeds don't.
  ///
  /// Costs roughly a day of horizon per 5 requests (5 prayers/day, more when
  /// pre-reminders are on), so this is ~6 days ahead rather than the ~8 the
  /// old flat 40 bought — and unlike the feeds it crowded out, the window is
  /// rebuilt every time the app is opened.
  static const int adhanWindow = iosPendingCap - reserved;
}
