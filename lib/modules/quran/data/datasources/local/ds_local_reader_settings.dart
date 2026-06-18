import 'package:quran/modules/quran/data/sources/local/box_reader_settings.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';

/// Reads/writes reader display preferences from the local box.
class DSLocalReaderSettings {
  DSLocalReaderSettings(this._box);
  final BoxReaderSettings _box;

  Future<void> init() => _box.init();

  EQuranFontMode getFontMode() =>
      EQuranFontModeX.fromStorage(_box.box.get(BoxReaderSettings.fontModeKey));

  Future<void> setFontMode(EQuranFontMode mode) =>
      _box.box.put(BoxReaderSettings.fontModeKey, mode.storageKey);
}
