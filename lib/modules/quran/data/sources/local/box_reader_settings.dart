import 'package:quran/core/utils/hive_box_base.dart';

/// Persists reader display preferences as primitive `String` values.
///
/// Uses a primitive box (no [TypeAdapter]) on purpose — it sidesteps the
/// codegen step entirely and survives the broken build_runner. Holds the Quran
/// font mode, the reading theme, the text-size scale, the bold flag and the
/// page-scroll mode, each as a `String`.
class BoxReaderSettings extends HiveBoxBase<String> {
  BoxReaderSettings() : super('quran_reader_settings');

  static const String fontModeKey = 'font_mode';

  /// The RESOLVED page colour last rendered. Kept as the migration source for
  /// [themeModeKey] — an install that pinned a theme before the follow-the-OS
  /// option existed had made a deliberate choice, and must keep it.
  static const String themeKey = 'reader_theme';

  /// What the user chose: `system` (follow the OS) or a pinned page colour.
  /// See `EReaderThemeMode`.
  static const String themeModeKey = 'reader_theme_mode';
  static const String fontScaleKey = 'font_scale';
  static const String fontBoldKey = 'font_bold';
  static const String scrollModeKey = 'scroll_mode';
}
