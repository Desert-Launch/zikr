/// Which QPC Mushaf font/glyph set the reader renders with.
///
/// - [plainV1]   black QPC V1 glyphs — the default, pixel-perfect Madani Mushaf
///   (the only set currently bundled).
/// - [plainV2]   black QPC V2 glyphs — alternate plain layout.
/// - [tajweedV4] KFGQPC V4 colour glyphs — Tajweed rule colours baked into the
///   font (Madd = red, Ghunnah = green, Qalqalah = blue, …). Requires the
///   bundled V4 fonts + V4 word-codes — see
///   `docs/plans/Tajweed_Approach_A_Plan.md`.
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
  /// reserved for when those fonts are added.
  String fontFamilyForPage(int page) => switch (this) {
        EQuranFontMode.plainV1 => 'QCF_P$page',
        EQuranFontMode.plainV2 => 'QCF_V2_P$page',
        EQuranFontMode.tajweedV4 => 'QCF_V4_P$page',
      };

  /// Asset path of the per-page TTF for [page].
  ///
  /// V1 fonts are zero-padded (`QCF_P001.TTF`); the V4 tajweed set from QUL is
  /// `p{page}.ttf` (non-padded). V2 is not bundled yet.
  String assetForPage(int page) {
    final padded = page.toString().padLeft(3, '0');
    return switch (this) {
      EQuranFontMode.plainV1 => 'assets/fonts/qpc/QCF_P$padded.TTF',
      EQuranFontMode.plainV2 => 'assets/fonts/qpc_v2/QCF_V2_P$padded.TTF',
      EQuranFontMode.tajweedV4 => 'assets/fonts/qpc_v4/p$page.ttf',
    };
  }

  /// Dataset folder the page layout is read from. V4 has its own line/word
  /// layout; V1 and V2 share the original layout (same words, different glyph).
  String get datasetFolder => switch (this) {
        EQuranFontMode.tajweedV4 => 'assets/data/mushaf_v4',
        _ => 'assets/data/mushaf_pages',
      };

  /// Whether glyphs carry their own (COLR/CPAL) colour. Only V4 does — the
  /// renderer leaves the base text colour as a fallback for uncoloured glyphs.
  bool get isColored => this == EQuranFontMode.tajweedV4;

  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a mode, defaulting to [plainV1].
  static EQuranFontMode fromStorage(String? value) =>
      EQuranFontMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => EQuranFontMode.plainV1,
      );
}
