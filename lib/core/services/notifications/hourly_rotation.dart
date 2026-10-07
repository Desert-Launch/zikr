import 'package:quran/core/services/notifications/notification_window.dart';

/// Which hourly zekr lands on which hour, day after day.
///
/// When the hourly range has at least as many hours as there are azkar, they
/// all fit in one day: slot `i` carries zekr `i % count` every day, so the feed
/// can be a set of plain daily repeats.
///
/// When the range is shorter, a day can't hold them all, so each day picks up
/// where the previous one stopped: day `k`, slot `i` carries zekr
/// `(k * slots + i) % count`. With 5 hours and 10 azkar, day 1 is azkar 1–5,
/// day 2 is 6–10 and day 3 is 1–5 again; with 12 azkar, day 3 is 11, 12, 1, 2,
/// 3. Neither OS can repeat a notification every N days, so that mode is armed
/// as dated one-shots a few days ahead — see `DSHourlyTasbih`.
///
/// Days are counted per *window-day* — the date the range starts on — so a
/// range running past midnight (22:00–02:00) keeps its after-midnight hours in
/// the same day as its evening ones.
class HourlyRotation {
  const HourlyRotation({required this.slotsPerDay, required this.zikrCount});

  /// Hours in the range — one notification each.
  final int slotsPerDay;

  /// Azkar to rotate through.
  final int zikrCount;

  /// True when every zekr fits in a single day of the range.
  bool get fitsInOneDay => zikrCount <= slotsPerDay;

  /// Days until every zekr has come round at least once — 1 when they fit in a
  /// day.
  int get daysToCoverAll {
    if (fitsInOneDay || slotsPerDay <= 0) return 1;
    return (zikrCount + slotsPerDay - 1) ~/ slotsPerDay;
  }

  /// Index of the zekr for [slot] on rotation day [day] (window-days since the
  /// anchor). [day] may be negative — a window-day that began before the
  /// anchor — and still lands on a valid row, as Dart's `%` never goes below 0
  /// for a positive divisor.
  int rowFor({required int day, required int slot}) {
    if (zikrCount <= 0) return 0;
    if (fitsInOneDay) return slot % zikrCount;
    return (day * slotsPerDay + slot) % zikrCount;
  }

  /// Day number of [date]'s calendar date (days since 1970-01-01).
  ///
  /// Counted on the UTC calendar so a DST change can't put two local dates 23
  /// or 25 hours apart and skew the division.
  static int epochDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// When slot [slot] of the window-day starting on [windowDay] fires, at
  /// [minute] past its hour. An hour before the range's first one is the
  /// after-midnight tail of a wrapping range, so it falls on the next date.
  static DateTime fireTime(
    DateTime windowDay,
    List<int> hours,
    int slot,
    int minute,
  ) {
    final hour = hours[slot];
    return DateTime(
      windowDay.year,
      windowDay.month,
      windowDay.day + (hour < hours.first ? 1 : 0),
      hour,
      minute,
    );
  }

  /// The start date of the window-day [now] falls in — or of the next one,
  /// once today's range has ended.
  ///
  /// This is "day 1" when the user saves a new range: the rotation opens with
  /// the range they are in or about to be in, never one that already finished.
  /// Saving 09:00–13:00 in the evening therefore opens tomorrow's range on
  /// zekr 1, instead of counting the finished range as day 1 and starting
  /// tomorrow on zekr 6.
  static DateTime currentWindowDay(NotificationWindow window, DateTime now) {
    final hours = window.hours;
    final wraps = hours.last < hours.first;
    for (var offset = -1; offset <= 1; offset++) {
      final start = DateTime(now.year, now.month, now.day + offset);
      final lastHourEnds = DateTime(
        start.year,
        start.month,
        start.day + (wraps ? 1 : 0),
        hours.last + 1,
      );
      if (lastHourEnds.isAfter(now)) return start;
    }
    return DateTime(now.year, now.month, now.day + 1);
  }
}
