/// Which QPC Mushaf font/glyph set the reader renders with.
///
/// - [plainV1]   legacy QPC V1 glyphs — RETIRED. The V1 font set is no longer
///   bundled; the value is kept only so persisted settings deserialise, and
///   [fromStorage] migrates it to [plainV2]. Never selectable in the UI.
/// - [plainV2]   black QPC V2 glyphs — the default, standard Madani Mushaf,
///   bundled as per-page fonts in `assets/fonts/qpc_v2/`.
/// - [tajweedV4] the Tajweed (coloured) reading mode. Despite the legacy name,
///   it no longer uses baked-colour V4 glyph fonts (Approach A, retired): it
///   renders via [WTajweedPage], which colours each token itself over the plain
///   Uthmani (Amiri) text — see `docs/plans/Tajweed_Approach_B_Plan.md`. It
///   therefore loads none of the per-page QPC glyph fonts.
enum EQuranFontMode {
  plainV1,
  plainV2,
  tajweedV4,
}

extension EQuranFontModeX on EQuranFontMode {
  /// Per-page font family, always the V2 `QCF_V2_P{page}` set — the only glyph
  /// font bundled now. The retired [plainV1] and the Amiri-rendered [tajweedV4]
  /// (which never queries a per-page family) resolve here too, so no caller can
  /// reference the deleted V1 family.
  String fontFamilyForPage(int page) => switch (this) {
        EQuranFontMode.plainV1 => 'QCF_V2_P$page',
        EQuranFontMode.plainV2 => 'QCF_V2_P$page',
        EQuranFontMode.tajweedV4 => 'QCF_V2_P$page',
      };

  /// Asset path of the per-page TTF for [page] — always the bundled V2 set
  /// (`QCF_V2_P001.TTF`). The retired [plainV1] and [tajweedV4] resolve here too
  /// so this never points at the deleted V1 assets if ever called.
  String assetForPage(int page) {
    final padded = page.toString().padLeft(3, '0');
    return switch (this) {
      EQuranFontMode.plainV1 => 'assets/fonts/qpc_v2/QCF_V2_P$padded.TTF',
      EQuranFontMode.plainV2 => 'assets/fonts/qpc_v2/QCF_V2_P$padded.TTF',
      EQuranFontMode.tajweedV4 => 'assets/fonts/qpc_v2/QCF_V2_P$padded.TTF',
    };
  }

  /// Dataset folder the page layout is read from. All modes share the original
  /// layout (same words); Tajweed colours are applied per-token on top.
  String get datasetFolder => 'assets/data/mushaf_pages';

  /// Whether the rendering relies on a baked-colour font whose palette we can't
  /// theme. Now always false: Tajweed colours are applied per-token by
  /// [WTajweedPage] (Approach B), so every mode follows the reader theme —
  /// including dark — and the old dark-mode cream lock is gone.
  bool get isColored => false;

  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a mode, defaulting to [plainV2].
  /// Legacy [plainV1] settings are migrated to [plainV2] (the V1 set is retired).
  static EQuranFontMode fromStorage(String? value) {
    if (value == EQuranFontMode.plainV1.name) return EQuranFontMode.plainV2;
    return EQuranFontMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => EQuranFontMode.plainV2,
    );
  }
}
