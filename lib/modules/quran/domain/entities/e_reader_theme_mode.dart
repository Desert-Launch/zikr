import 'dart:ui' show Brightness;

import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';

/// What the user CHOSE for the reading surface, as opposed to what is currently
/// rendered ([ReaderTheme], which is always a concrete page colour).
///
/// [system] follows the device's light/dark setting and keeps following it;
/// picking any other value pins that surface and ignores the OS from then on.
/// Declaration order IS the order shown in the settings picker.
enum EReaderThemeMode { system, white, light, dark }

extension EReaderThemeModeX on EReaderThemeMode {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// The concrete page theme to render.
  ///
  /// This is the ONLY place `system` is turned into a colour, so the palette
  /// and the light/dark glyph-font variant can never disagree — both read the
  /// single [ReaderTheme] this returns. A second, independently-derived dark
  /// flag is exactly how black glyphs end up on a dark page.
  ///
  /// Dark brightness resolves to [ReaderTheme.dark]; light resolves to
  /// [ReaderTheme.light], the warm off-white, NOT [ReaderTheme.white] — light
  /// has always been the app's default surface, so following the system in
  /// daylight leaves the reader looking exactly as it did before.
  ReaderTheme resolve(Brightness platformBrightness) => switch (this) {
    EReaderThemeMode.system =>
      platformBrightness == Brightness.dark
          ? ReaderTheme.dark
          : ReaderTheme.light,
    EReaderThemeMode.white => ReaderTheme.white,
    EReaderThemeMode.light => ReaderTheme.light,
    EReaderThemeMode.dark => ReaderTheme.dark,
  };

  /// The mode that pins [theme] — used to migrate installs that persisted an
  /// explicit reading theme before this setting existed.
  static EReaderThemeMode pinning(ReaderTheme theme) => switch (theme) {
    ReaderTheme.white => EReaderThemeMode.white,
    ReaderTheme.light => EReaderThemeMode.light,
    ReaderTheme.dark => EReaderThemeMode.dark,
  };

  /// Resolves a persisted token, falling back to [EReaderThemeMode.system].
  /// The caller handles the pre-setting migration; this only parses.
  static EReaderThemeMode fromStorage(String? value) =>
      EReaderThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => EReaderThemeMode.system,
      );
}
