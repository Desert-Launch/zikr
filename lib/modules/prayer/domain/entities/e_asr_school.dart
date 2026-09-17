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

extension EAsrSchoolX on EAsrSchool {
  /// Flat i18n key for the picker row.
  String get labelKey => switch (this) {
    EAsrSchool.standard => 'prayer_calc_asr_standard',
    EAsrSchool.hanafi => 'prayer_calc_asr_hanafi',
  };

  /// Stored index (also the legacy `MPrayerSettings.madhabIndex` value, so
  /// existing installs keep the school they already chose).
  int get storageIndex => index;

  /// Reads a persisted index back, tolerating anything out of range.
  static EAsrSchool fromIndex(int? index) =>
      index == 1 ? EAsrSchool.hanafi : EAsrSchool.standard;
}
