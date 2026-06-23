import 'package:quran/modules/quran/data/sources/local/box_reader_settings.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';

/// Reads/writes reader display preferences from the local box.
class DSLocalReaderSettings {
  DSLocalReaderSettings(this._box);
  final BoxReaderSettings _box;

  /// Allowed text-size range, mirrored in [CBReaderSettings] and the reader.
  static const double minScale = 0.8;
  static const double maxScale = 1.5;

  Future<void> init() => _box.init();

  EQuranFontMode getFontMode() =>
      EQuranFontModeX.fromStorage(_box.box.get(BoxReaderSettings.fontModeKey));

  Future<void> setFontMode(EQuranFontMode mode) =>
      _box.box.put(BoxReaderSettings.fontModeKey, mode.storageKey);

  ReaderTheme getTheme() =>
      ReaderThemeX.fromStorage(_box.box.get(BoxReaderSettings.themeKey));

  Future<void> setTheme(ReaderTheme theme) =>
      _box.box.put(BoxReaderSettings.themeKey, theme.storageKey);

  double getFontScale() {
    final raw = double.tryParse(_box.box.get(BoxReaderSettings.fontScaleKey) ?? '');
    if (raw == null) return 1.0;
    return raw.clamp(minScale, maxScale);
  }

  Future<void> setFontScale(double scale) => _box.box.put(
        BoxReaderSettings.fontScaleKey,
        scale.clamp(minScale, maxScale).toString(),
      );
}
