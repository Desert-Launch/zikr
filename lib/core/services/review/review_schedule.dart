/// When the automatic store review ask is due.
///
/// The app only decides when to ASK — the OS decides whether the dialog shows,
/// and neither store reports back whether it did or whether the user reviewed:
/// - App Store: a user who hasn't rated the app on the device sees the prompt
///   at most 3 times in 365 days. One who has only sees it again on a new
///   version, more than 365 days after their review.
/// - Google Play: a time-bound quota whose value is undisclosed and may change;
///   asks under a month apart may not show.
///
/// The cadence is built on Apple's documented limit, the only published one,
/// and applied on both platforms: the first ask [firstDelay] after the first
/// open, then one every [interval] after the previous ask. Spacing from the
/// previous ask (not from a fixed calendar) means a late open shifts the rest
/// of the cadence instead of bunching two asks together, so no 365-day window
/// ever holds more than [maxPerYear] — no ask is wasted on a suppressed prompt.
class ReviewSchedule {
  ReviewSchedule._();

  /// App Store's cap on review prompts per 365 days.
  static const int maxPerYear = 3;

  static const Duration firstDelay = Duration(days: 30);

  /// 122 days: [maxPerYear] asks fit a year, a fourth can't.
  static final Duration interval = Duration(days: (365 / maxPerYear).ceil());

  static DateTime nextDue({
    required DateTime firstOpenedAt,
    DateTime? lastRequestedAt,
  }) => lastRequestedAt?.add(interval) ?? firstOpenedAt.add(firstDelay);

  static bool isDue({
    required DateTime now,
    required DateTime firstOpenedAt,
    DateTime? lastRequestedAt,
  }) => !now.isBefore(
    nextDue(firstOpenedAt: firstOpenedAt, lastRequestedAt: lastRequestedAt),
  );
}
