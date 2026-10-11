import 'package:in_app_review/in_app_review.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/review/review_schedule.dart';

/// Asks for a store review on app open, on the cadence of [ReviewSchedule].
///
/// Native dialog only, never a custom one or a question in front of it: Google
/// Play's guidelines forbid asking anything ("Do you like the app?") before the
/// review card, and Apple disallows custom review prompts.
class ReviewPrompter {
  ReviewPrompter(this._settings);

  final BoxAppSettings _settings;

  static const String _tag = 'ReviewPrompter';

  /// Lets the splash hand over to Home before the dialog covers the screen.
  static const Duration _settle = Duration(seconds: 4);

  /// Stamps the first open, then asks for a review if one is due. Call once
  /// per cold start, after any permission dialog has been answered — iOS
  /// won't stack a review prompt on top of another system alert.
  Future<void> maybeRequest() async {
    final now = DateTime.now();
    final s = _settings.current();
    final firstOpenedAt = s.firstOpenedAt;
    if (firstOpenedAt == null) {
      await _settings.setFirstOpenedAt(now);
      return;
    }
    if (s.reviewDone || !s.hasSeenOnboarding) return;
    final due = ReviewSchedule.isDue(
      now: now,
      firstOpenedAt: firstOpenedAt,
      lastRequestedAt: s.reviewLastRequestedAt,
    );
    if (!due) return;

    final review = InAppReview.instance;
    // False on Android without the Play Store; checked again next launch.
    if (!await review.isAvailable()) return;
    await Future<void>.delayed(_settle);
    // Stamped before asking: the call can't tell whether the dialog showed,
    // and the ask is what spends the store's quota.
    await _settings.setReviewLastRequestedAt(now);
    await review.requestReview();
    AppLogger.info('Store review requested', tag: _tag);
  }

  /// The user went to the store listing to review — stop asking.
  Future<void> markReviewed() => _settings.setReviewDone();
}
