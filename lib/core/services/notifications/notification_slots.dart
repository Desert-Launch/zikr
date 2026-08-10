/// Time-slot arithmetic shared by every scheduler that has to stay clear of
/// the other feeds (prayer, azkar/quran, salawat, hourly zekr).
///
/// Everything works in **minutes since midnight** rather than `hour`/`minute`
/// pairs. Comparing within an hour looks right and isn't: 12:55 and 13:00 are
/// five minutes apart but live in different hours, so an hour-scoped check
/// silently lets them stack.
class NotificationSlots {
  NotificationSlots._();

  /// Minimum spacing (minutes) between any two notifications.
  static const int gapMinutes = 10;

  static const int _minutesPerDay = 24 * 60;

  /// Flattens same-day clock times into minutes-since-midnight.
  static List<int> minutesOfDay(Iterable<DateTime> times) => [
    for (final t in times) t.hour * 60 + t.minute,
  ];

  /// True when [minuteOfDay] keeps at least [gap] minutes from every entry in
  /// [reserved].
  static bool isClear(
    int minuteOfDay,
    List<int> reserved, {
    int gap = gapMinutes,
  }) => reserved.every((m) => (m - minuteOfDay).abs() >= gap);

  /// First of [candidates] (minutes past [hour]) that clears every reserved
  /// time. Falls back to the first candidate — a preferred slot beats dropping
  /// the notification.
  static int pickMinute({
    required int hour,
    required List<int> reserved,
    required List<int> candidates,
    int gap = gapMinutes,
  }) {
    for (final candidate in candidates) {
      if (isClear(hour * 60 + candidate, reserved, gap: gap)) return candidate;
    }
    return candidates.first;
  }

  /// Nearest clear time to [minuteOfDay], searched outwards in 5-minute steps
  /// (later first, so a reminder drifts forward rather than arriving early).
  /// Returns [minuteOfDay] unchanged when it's already clear, or when nothing
  /// within [maxShift] works.
  static int nudge({
    required int minuteOfDay,
    required List<int> reserved,
    int gap = gapMinutes,
    int maxShift = 30,
  }) {
    if (isClear(minuteOfDay, reserved, gap: gap)) return minuteOfDay;
    for (var shift = 5; shift <= maxShift; shift += 5) {
      for (final candidate in [minuteOfDay + shift, minuteOfDay - shift]) {
        if (candidate < 0 || candidate >= _minutesPerDay) continue;
        if (isClear(candidate, reserved, gap: gap)) return candidate;
      }
    }
    return minuteOfDay;
  }
}
