import 'package:quran/core/utils/hive_box_base.dart';

/// Persists reader display preferences as primitive `String` values.
///
/// Uses a primitive box (no [TypeAdapter]) on purpose — it sidesteps the
/// codegen step entirely and survives the broken build_runner. Currently holds
/// only the Quran font mode (keyed by [fontModeKey]).
class BoxReaderSettings extends HiveBoxBase<String> {
  BoxReaderSettings() : super('quran_reader_settings');

  static const String fontModeKey = 'font_mode';
}
