/// Reading-surface background for the Mushaf page.
///
/// - [light] warm white paper — the default.
/// - [sepia] cream paper, easier on the eyes in soft light.
/// - [dark]  night background with light glyphs.
///
/// Drives [w_mushaf_page]'s page colour; persisted (and shared with the open
/// reader) through `CBReaderSettings`.
enum ReaderTheme { light, sepia, dark }

extension ReaderThemeX on ReaderTheme {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a theme, defaulting to [light].
  static ReaderTheme fromStorage(String? value) =>
      ReaderTheme.values.firstWhere(
        (t) => t.name == value,
        orElse: () => ReaderTheme.light,
      );
}
