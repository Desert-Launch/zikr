/// Whether the calculation authority is chosen by Aladhan from the
/// coordinates, or pinned by the user.
enum ECalculationMode {
  /// The default. No `method` parameter is sent, and Aladhan picks the
  /// authority closest to the supplied location — which is why the app works
  /// in a country nobody wrote a mapping for. What it picked comes back in
  /// `meta.method` and is stored, so the UI can name it.
  automatic,

  /// The user pinned a specific authority (their mosque follows a different
  /// one). That id is sent as `method` on every request.
  manual,
}

extension ECalculationModeX on ECalculationMode {
  String get labelKey => switch (this) {
    ECalculationMode.automatic => 'prayer_calc_method_auto',
    ECalculationMode.manual => 'prayer_calc_method_manual',
  };

  static ECalculationMode fromIndex(int? index) =>
      index == 1 ? ECalculationMode.manual : ECalculationMode.automatic;
}
