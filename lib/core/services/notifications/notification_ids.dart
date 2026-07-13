/// Centralized notification-id bands so the JSON-driven feeds never collide
/// with each other or with the feature schedulers.
///
/// Existing bands owned elsewhere (kept here for reference — do not reuse):
///   * 5000–5014 → hourly tasbih / zekr (`DSHourlyTasbih`)
///   * 5099, 5108–5122 → salawat reminders (`DSSalawatReminder`)
///   * 7000–7999 → user reminders (`MReminder.notifId`)
///   * 200000–399999 → adhan window (`AdhanScheduler`)
///   * 999999 → adhan test
class NotificationIds {
  NotificationIds._();

  // ── Init notifications (init_notifications.json) — 9000–9005 ──
  static const int azkarMorning = 9000;
  static const int azkarEvening = 9001;
  static const int azkarSleep = 9002;
  static const int quranAlMulk = 9003;
  static const int quranAlBaqara = 9004;
  static const int quranAlKahf = 9005;

  /// Maps a JSON string id (e.g. `azkar_morning`) to its stable int id.
  /// Returns null for an unknown id (the entry is skipped + logged).
  static int? forStringId(String id) => switch (id) {
    'azkar_morning' => azkarMorning,
    'azkar_evening' => azkarEvening,
    'azkar_sleep' => azkarSleep,
    'quran_almulk' => quranAlMulk,
    'quran_albaqara' => quranAlBaqara,
    'quran_alkahf' => quranAlKahf,
    _ => null,
  };
}
