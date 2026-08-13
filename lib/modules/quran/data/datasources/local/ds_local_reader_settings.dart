import 'package:quran/modules/quran/data/sources/local/box_reader_settings.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';

/// Reads/writes reader display preferences from the local box.
class DSLocalReaderSettings {
  DSLocalReaderSettings(this._box);
  final BoxReaderSettings _box;

  /// Allowed text-size range, mirrored in [CBReaderSettings] and the reader.
  /// A value persisted by an older build outside this range is clamped on read,
  /// so lowering the ceiling cannot strand a reader at a size the slider can no
  /// longer express.
  static const double minScale = 0.8;
  static const double maxScale = 1.6;

  Future<void> init() => _box.init();

  EQuranFontMode getFontMode() =>
      EQuranFontModeX.fromStorage(_box.box.get(BoxReaderSettings.fontModeKey));

  Future<void> setFontMode(EQuranFontMode mode) =>
      _box.box.put(BoxReaderSettings.fontModeKey, mode.storageKey);

  ReaderTheme getTheme() =>
      ReaderThemeX.fromStorage(_box.box.get(BoxReaderSettings.themeKey));

  Future<void> setTheme(ReaderTheme theme) =>
      _box.box.put(BoxReaderSettings.themeKey, theme.storageKey);

  /// The user's page-theme choice, migrating installs that predate it.
  ///
  /// Migration rule: a stored `reader_theme` means the user picked that surface
  /// deliberately, so it maps to the matching PINNED mode rather than to
  /// `system` — following the OS would silently override a choice they already
  /// made. Only an install with no stored theme at all starts on `system`.
  EReaderThemeMode getThemeMode() {
    final stored = _box.box.get(BoxReaderSettings.themeModeKey);
    if (stored != null) return EReaderThemeModeX.fromStorage(stored);
    final legacy = _box.box.get(BoxReaderSettings.themeKey);
    if (legacy == null) return EReaderThemeMode.system;
    return EReaderThemeModeX.pinning(ReaderThemeX.fromStorage(legacy));
  }

  Future<void> setThemeMode(EReaderThemeMode mode) =>
      _box.box.put(BoxReaderSettings.themeModeKey, mode.storageKey);

  double getFontScale() {
    final raw = double.tryParse(
      _box.box.get(BoxReaderSettings.fontScaleKey) ?? '',
    );
    if (raw == null) return 1.0;
    return raw.clamp(minScale, maxScale);
  }

  Future<void> setFontScale(double scale) => _box.box.put(
    BoxReaderSettings.fontScaleKey,
    scale.clamp(minScale, maxScale).toString(),
  );

  /// Defaults to ON, so the gesture is discoverable without a settings trip.
  /// Only an explicit `'false'` disables it — an absent key means "not chosen
  /// yet", which is the default, not off.
  bool getPinchZoom() =>
      _box.box.get(BoxReaderSettings.pinchZoomKey) != 'false';

  Future<void> setPinchZoom(bool enabled) =>
      _box.box.put(BoxReaderSettings.pinchZoomKey, enabled.toString());

  bool getFontBold() => _box.box.get(BoxReaderSettings.fontBoldKey) == 'true';

  Future<void> setFontBold(bool bold) =>
      _box.box.put(BoxReaderSettings.fontBoldKey, bold.toString());

  EReaderScrollMode getScrollMode() => EReaderScrollModeX.fromStorage(
    _box.box.get(BoxReaderSettings.scrollModeKey),
  );

  Future<void> setScrollMode(EReaderScrollMode mode) =>
      _box.box.put(BoxReaderSettings.scrollModeKey, mode.storageKey);
}
