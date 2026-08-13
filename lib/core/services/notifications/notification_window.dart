import 'package:equatable/equatable.dart';

/// The hours of the day in which a repeating reminder feed is allowed to fire.
///
/// Scoped deliberately: only the salawat reminder and the hourly zekr consult
/// it. Prayer times, the adhan, the azkar/quran feed, khatma and the user's own
/// reminders are NOT windowed — a prayer that falls outside it must still fire.
///
/// Both bounds are inclusive hours (`8`–`22` means 08:00 through 22:59), which
/// matches the fixed window this replaced. A [startHour] later than [endHour]
/// wraps past midnight, so "quiet while I sleep" is expressible as e.g. 22 → 7.
class NotificationWindow extends Equatable {
  const NotificationWindow({required this.startHour, required this.endHour});

  /// The window every install had before it became configurable — 08:00–22:00.
  /// Also what a record written before the setting existed decodes to, so
  /// upgrading changes nothing until the user moves it.
  static const NotificationWindow fallback = NotificationWindow(
    startHour: defaultStartHour,
    endHour: defaultEndHour,
  );

  static const int defaultStartHour = 8;
  static const int defaultEndHour = 22;

  final int startHour;
  final int endHour;

  /// Every hour in the window, in fire order, wrapping past midnight when
  /// [startHour] > [endHour].
  ///
  /// Always non-empty: a window is at least the hour it starts in, so a bad
  /// pair can never silence a feed the user believes is on.
  List<int> get hours {
    final start = startHour % 24;
    final end = endHour % 24;
    if (start <= end) return [for (var h = start; h <= end; h++) h];
    return [
      for (var h = start; h < 24; h++) h,
      for (var h = 0; h <= end; h++) h,
    ];
  }

  /// Picks every [step]-th hour of the window, starting at [startHour] — the
  /// salawat interval mode. `step <= 1` returns every hour.
  List<int> hoursEvery(int step) {
    final all = hours;
    if (step <= 1) return all;
    return [for (var i = 0; i < all.length; i += step) all[i]];
  }

  bool contains(int hour) => hours.contains(hour % 24);

  @override
  List<Object?> get props => [startHour, endHour];
}
