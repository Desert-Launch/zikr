import 'package:quran/core/utils/hive_box_base.dart';

/// Persists reader display preferences as primitive `String` values.
///
/// Uses a primitive box (no [TypeAdapter]) on purpose — it sidesteps the
/// codegen step entirely and survives the broken build_runner. Holds the Quran
/// font mode, the reading theme and the text-size scale, each as a `String`.
class BoxReaderSettings extends HiveBoxBase<String> {
  BoxReaderSettings() : super('quran_reader_settings');

  static const String fontModeKey = 'font_mode';
  static const String themeKey = 'reader_theme';
  static const String fontScaleKey = 'font_scale';
}
