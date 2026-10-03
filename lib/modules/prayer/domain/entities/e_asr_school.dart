/// Which juristic convention decides when Asr begins.
///
/// Independent of the calculation method: a user in Egypt on the Egyptian
/// authority may still follow the Hanafi Asr, and the two settings are stored
/// and sent separately.
enum EAsrSchool {
  /// Shafi'i / Maliki / Hanbali — Asr when an object's shadow equals its
  /// length. Aladhan calls this `school=0`.
  standard,

  /// Hanafi — Asr when the shadow reaches twice the object's length,
  /// roughly an hour later. Aladhan `school=1`.
  hanafi,
}
