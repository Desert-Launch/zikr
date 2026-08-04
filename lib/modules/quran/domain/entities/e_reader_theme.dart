/// Reading-surface background for the Mushaf page. Declaration order IS the
/// order shown in the settings picker.
///
/// - [white] pure white paper — the first option.
/// - [light] warm off-white paper — the app's long-standing default.
/// - [dark]  night background with light glyphs.
///
/// The former `sepia` (cream) option was retired; bookmarks persisted under it
/// resolve back to [light] via [ReaderThemeX.fromStorage].
///
/// Drives [w_mushaf_v4_page]'s page colour; persisted (and shared with the open
/// reader) through `CBReaderSettings`.
enum ReaderTheme { white, light, dark }

extension ReaderThemeX on ReaderTheme {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a theme, defaulting to [light].
  /// Retired tokens (e.g. `sepia`) fall through to the default, so an existing
  /// install keeps a warm paper surface rather than flipping to white.
  static ReaderTheme fromStorage(String? value) => ReaderTheme.values
      .firstWhere((t) => t.name == value, orElse: () => ReaderTheme.light);
}
