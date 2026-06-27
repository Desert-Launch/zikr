/// Which QPC Mushaf font/glyph set the reader renders with.
///
/// - [plainV1]   black QPC V1 glyphs — the default, pixel-perfect Madani Mushaf
///   (the only set currently bundled).
/// - [plainV2]   black QPC V2 glyphs — alternate plain layout.
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
  /// Per-page font family. V1 keeps the existing `QCF_P{page}` family so the
  /// current renderer/loader is untouched in the default mode.
  ///
  /// NOTE: V2 is not bundled yet (the V2 font set isn't shipped); its family is
  /// reserved for when those fonts are added. tajweedV4 renders via Amiri in
  /// [WTajweedPage] and never queries a per-page family, so it falls back to V1.
  String fontFamilyForPage(int page) => switch (this) {
        EQuranFontMode.plainV1 => 'QCF_P$page',
        EQuranFontMode.plainV2 => 'QCF_V2_P$page',
        EQuranFontMode.tajweedV4 => 'QCF_P$page',
      };

  /// Asset path of the per-page TTF for [page].
  ///
  /// V1 fonts are zero-padded (`QCF_P001.TTF`). V2 is not bundled yet. tajweedV4
  /// loads no per-page glyph font (Approach B) — it falls back to the V1 asset
  /// so this never resolves to a missing path if ever called.
  String assetForPage(int page) {
    final padded = page.toString().padLeft(3, '0');
    return switch (this) {
      EQuranFontMode.plainV1 => 'assets/fonts/qpc/QCF_P$padded.TTF',
      EQuranFontMode.plainV2 => 'assets/fonts/qpc_v2/QCF_V2_P$padded.TTF',
      EQuranFontMode.tajweedV4 => 'assets/fonts/qpc/QCF_P$padded.TTF',
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

  /// Resolves a persisted [value] back to a mode, defaulting to [plainV1].
  static EQuranFontMode fromStorage(String? value) =>
      EQuranFontMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => EQuranFontMode.plainV1,
      );
}
