import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_bold.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_bold.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_theme.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// App-wide reader display settings.
///
/// Registered as a SINGLETON so the settings screen and any open Mushaf reader
/// share one instance — changing the font mode, reading theme or text size
/// re-renders the reader instantly (the renderer listens via `BlocSelector`,
/// `CBMushafReader` mirrors this state). Loads the persisted values once on
/// creation; the box is opened in `main()` before the first frame.
class CBReaderSettings extends Cubit<SReaderSettings> {
  CBReaderSettings(
    this._getFontMode,
    this._setFontMode,
    this._getTheme,
    this._setTheme,
    this._getFontScale,
    this._setFontScale,
    this._getFontBold,
    this._setFontBold,
    this._getScrollMode,
    this._setScrollMode,
  ) : super(const SReaderSettings()) {
    load();
  }

  final UCGetFontMode _getFontMode;
  final UCSetFontMode _setFontMode;
  final UCGetReaderTheme _getTheme;
  final UCSetReaderTheme _setTheme;
  final UCGetFontScale _getFontScale;
  final UCSetFontScale _setFontScale;
  final UCGetFontBold _getFontBold;
  final UCSetFontBold _setFontBold;
  final UCGetReaderScrollMode _getScrollMode;
  final UCSetReaderScrollMode _setScrollMode;

  /// Allowed text-size range; mirrors the data layer's clamp.
  ///
  /// The range runs past the printed page's own size on purpose: above
  /// `kBigTextThreshold` the reader stops reproducing the printed line breaks
  /// and reflows the page as one stream, which is what makes the large end of
  /// the range readable instead of a page of stranded words.
  ///
  /// The scale is continuous — any value in the range is valid, not just round
  /// steps — so the slider is free of divisions.
  static const double minScale = 0.8;
  static const double maxScale = 1.6;

  /// The printed Mushaf's own size — what the reset control returns to.
  static const double defaultScale = 1.0;

  Future<void> load() async {
    final mode = await _getFontMode();
    mode.fold((_) {}, (m) => emit(state.copyWith(fontMode: m)));
    final theme = await _getTheme();
    theme.fold((_) {}, (t) => emit(state.copyWith(theme: t)));
    final scale = await _getFontScale();
    scale.fold((_) {}, (s) => emit(state.copyWith(fontScale: s)));
    final bold = await _getFontBold();
    bold.fold((_) {}, (b) => emit(state.copyWith(bold: b)));
    final scrollMode = await _getScrollMode();
    scrollMode.fold((_) {}, (m) => emit(state.copyWith(scrollMode: m)));
  }

  Future<void> setFontMode(EQuranFontMode mode) async {
    if (mode == state.fontMode) return;
    // Optimistic: emit first so the open reader re-renders immediately, then
    // persist (best-effort — the next change retries).
    emit(state.copyWith(fontMode: mode));
    await _setFontMode(mode);
  }

  Future<void> setTheme(ReaderTheme theme) async {
    if (theme == state.theme) return;
    emit(state.copyWith(theme: theme));
    await _setTheme(theme);
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    if (clamped == state.fontScale) return;
    emit(state.copyWith(fontScale: clamped));
    await _setFontScale(clamped);
  }

  /// Back to the printed size. Deliberately leaves [SReaderSettings.bold]
  /// alone — this resets the size control, not the whole text style.
  Future<void> resetFontScale() => setFontScale(defaultScale);

  Future<void> setBold(bool bold) async {
    if (bold == state.bold) return;
    emit(state.copyWith(bold: bold));
    await _setFontBold(bold);
  }

  /// Switches the reader between sideways paging and one continuous column.
  /// An open reader picks this up through `CBMushafReader` and keeps its place.
  Future<void> setScrollMode(EReaderScrollMode mode) async {
    if (mode == state.scrollMode) return;
    emit(state.copyWith(scrollMode: mode));
    await _setScrollMode(mode);
  }
}
