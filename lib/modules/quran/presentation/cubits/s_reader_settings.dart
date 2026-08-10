import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';

/// App-wide reader display settings shared by the reader and the settings
/// screen. Kept intentionally small; transient per-session state (selection,
/// chrome visibility, current page) stays in `SMushafReader`.
class SReaderSettings extends Equatable {
  const SReaderSettings({
    this.fontMode = EQuranFontMode.plainV2,
    this.theme = ReaderTheme.light,
    this.fontScale = 1.0,
    this.bold = false,
    this.scrollMode = EReaderScrollMode.horizontal,
  });

  final EQuranFontMode fontMode;
  final ReaderTheme theme;
  final double fontScale;

  /// Renders the Mushaf glyphs at a heavier weight. Off by default — the
  /// printed page is the reference.
  final bool bold;

  /// Whether the reader turns pages sideways or scrolls the Mushaf as one
  /// continuous column.
  final EReaderScrollMode scrollMode;

  SReaderSettings copyWith({
    EQuranFontMode? fontMode,
    ReaderTheme? theme,
    double? fontScale,
    bool? bold,
    EReaderScrollMode? scrollMode,
  }) =>
      SReaderSettings(
        fontMode: fontMode ?? this.fontMode,
        theme: theme ?? this.theme,
        fontScale: fontScale ?? this.fontScale,
        bold: bold ?? this.bold,
        scrollMode: scrollMode ?? this.scrollMode,
      );

  @override
  List<Object?> get props => [fontMode, theme, fontScale, bold, scrollMode];
}
