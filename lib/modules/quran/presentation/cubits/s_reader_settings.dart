import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';

/// App-wide reader display settings shared by the reader and the settings
/// screen. Kept intentionally small; transient per-session state (selection,
/// chrome visibility, current page) stays in `SMushafReader`.
class SReaderSettings extends Equatable {
  const SReaderSettings({
    this.fontMode = EQuranFontMode.plainV2,
    this.theme = ReaderTheme.light,
    this.themeMode = EReaderThemeMode.system,
    this.fontScale = 1.0,
    this.bold = false,
    this.pinchZoom = true,
    this.scrollMode = EReaderScrollMode.horizontal,
  });

  final EQuranFontMode fontMode;

  /// The page colour actually rendered — always concrete, never `system`.
  /// Everything downstream (page palette AND the light/dark glyph-font variant)
  /// reads this one value, so the two can never disagree.
  final ReaderTheme theme;

  /// What the user chose: follow the device, or a pinned colour. Drives the
  /// picker's selection; [theme] is what it resolved to.
  final EReaderThemeMode themeMode;
  final double fontScale;

  /// Renders the Mushaf glyphs at a heavier weight. Off by default — the
  /// printed page is the reference.
  final bool bold;

  /// Whether a two-finger pinch on the Mushaf changes [fontScale]. On by
  /// default; turning it off leaves the size slider as the only control, for
  /// readers who keep triggering the gesture by accident.
  final bool pinchZoom;

  /// Whether the reader turns pages sideways or scrolls the Mushaf as one
  /// continuous column.
  final EReaderScrollMode scrollMode;

  SReaderSettings copyWith({
    EQuranFontMode? fontMode,
    ReaderTheme? theme,
    EReaderThemeMode? themeMode,
    double? fontScale,
    bool? bold,
    bool? pinchZoom,
    EReaderScrollMode? scrollMode,
  }) => SReaderSettings(
    fontMode: fontMode ?? this.fontMode,
    theme: theme ?? this.theme,
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    bold: bold ?? this.bold,
    pinchZoom: pinchZoom ?? this.pinchZoom,
    scrollMode: scrollMode ?? this.scrollMode,
  );

  @override
  List<Object?> get props => [
    fontMode,
    theme,
    themeMode,
    fontScale,
    bold,
    pinchZoom,
    scrollMode,
  ];
}
