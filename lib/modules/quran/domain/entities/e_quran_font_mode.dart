/// How the Mushaf reader renders the QPC-V4 page glyphs.
///
/// - [plainV1]   legacy value — RETIRED. Kept only so old persisted settings
///   deserialise; [fromStorage] migrates it to [plainV2]. Never selectable.
/// - [plainV2]   plain Mushaf — the QPC-V4 colour font with every glyph collapsed
///   to a single uniform colour (black on a light page, white on a dark one).
///   The default.
/// - [tajweedV4] coloured Tajweed — the same per-page QPC-V4 font with its baked
///   CPAL tajweed palette, so the letters carry their tajweed colours.
///
/// Both selectable modes share the same page data and both font variants are
/// registered per page by `DSQpcV4FontLoader`, so switching is instant.
enum EQuranFontMode {
  plainV1,
  plainV2,
  tajweedV4,
}

extension EQuranFontModeX on EQuranFontMode {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a mode, defaulting to [plainV2].
  /// Legacy [plainV1] settings are migrated to [plainV2] (V1 is retired).
  static EQuranFontMode fromStorage(String? value) {
    if (value == EQuranFontMode.plainV1.name) return EQuranFontMode.plainV2;
    return EQuranFontMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => EQuranFontMode.plainV2,
    );
  }
}
