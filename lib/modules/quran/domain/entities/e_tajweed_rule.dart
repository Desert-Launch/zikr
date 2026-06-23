/// The 7 Tajweed rule categories the app colours.
///
/// Mapped at build time from cpfair's 18-rule dataset (CC BY 4.0) onto the
/// app's existing legend (see `w_tajweed_legend_sheet.dart` and the plan
/// `docs/plans/Tajweed_Approach_B_Plan.md` §3). Each value renders in its own
/// theme-aware colour via `tajweedColour(...)`.
enum ETajweedRule {
  /// Obligatory/necessary Madd (muttasil + laazim) — red.
  maddObligatory,

  /// Permissible Madd (natural, munfasil, 'aaridh) — orange.
  maddPermissible,

  /// Ghunnah (nasalization) — green.
  ghunnah,

  /// Qalqalah (echo) — blue.
  qalqalah,

  /// Ikhfa / Idgham family — light blue.
  ikhfaIdgham,

  /// Iqlab — teal.
  iqlab,

  /// Silent letters (incl. hamzat al-wasl, laam shamsiyyah) — grey.
  silent;

  /// Resolves a dataset rule key (e.g. `"madd_obligatory"`) to its category,
  /// or `null` for an uncoloured token.
  static ETajweedRule? fromKey(String? key) => switch (key) {
    'madd_obligatory' => maddObligatory,
    'madd_permissible' => maddPermissible,
    'ghunnah' => ghunnah,
    'qalqalah' => qalqalah,
    'ikhfa_idgham' => ikhfaIdgham,
    'iqlab' => iqlab,
    'silent' => silent,
    _ => null,
  };

  /// The i18n key for this rule's legend label.
  String get legendKey => switch (this) {
    maddObligatory => 'quran_tajweed_madd',
    maddPermissible => 'quran_tajweed_madd_permissible',
    ghunnah => 'quran_tajweed_ghunnah',
    qalqalah => 'quran_tajweed_qalqalah',
    ikhfaIdgham => 'quran_tajweed_ikhfa',
    iqlab => 'quran_tajweed_iqlab',
    silent => 'quran_tajweed_silent',
  };
}
