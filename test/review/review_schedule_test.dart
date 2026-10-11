import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/review/review_schedule.dart';

void main() {
  final firstOpenedAt = DateTime(2026, 1, 1, 9);

  /// Days after [firstOpenedAt] on which an app opened at [openDays] asks.
  List<int> asksFor(Iterable<int> openDays) {
    final asks = <int>[];
    DateTime? last;
    for (final day in openDays) {
      final now = firstOpenedAt.add(Duration(days: day));
      final due = ReviewSchedule.isDue(
        now: now,
        firstOpenedAt: firstOpenedAt,
        lastRequestedAt: last,
      );
      if (!due) continue;
      asks.add(day);
      last = now;
    }
    return asks;
  }

  test('the interval fits the store limit in a year, and no more', () {
    final days = ReviewSchedule.interval.inDays;
    expect(days, 122);
    expect(days * (ReviewSchedule.maxPerYear - 1), lessThan(365));
    expect(days * ReviewSchedule.maxPerYear, greaterThan(365));
  });

  test('nothing before the first month', () {
    expect(asksFor(List.generate(30, (d) => d)), isEmpty);
  });

  test('opened daily: month one, then twice more in the first year', () {
    final asks = asksFor(List.generate(365 * 3, (d) => d));
    expect(asks.where((d) => d < 365), [30, 152, 274]);
    expect(asks.take(6), [30, 152, 274, 396, 518, 640]);
  });

  test('a late open shifts the cadence instead of bunching asks', () {
    // Away from day 31 to day 270: the day-152 ask happens on 270, and the
    // next waits a full interval rather than landing on day 274.
    final opens = [30, ...List.generate(600, (d) => d + 270)];
    expect(asksFor(opens).take(3), [30, 270, 392]);
  });

  test('no 365-day window ever holds more than the store limit', () {
    final asks = asksFor(List.generate(365 * 5, (d) => d));
    for (final start in asks) {
      final inWindow = asks.where((d) => d >= start && d < start + 365);
      expect(inWindow.length, lessThanOrEqualTo(ReviewSchedule.maxPerYear));
    }
  });
}
