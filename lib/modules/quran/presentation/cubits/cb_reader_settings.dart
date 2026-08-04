import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_scale.dart';
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
  ) : super(const SReaderSettings()) {
    load();
  }

  final UCGetFontMode _getFontMode;
  final UCSetFontMode _setFontMode;
  final UCGetReaderTheme _getTheme;
  final UCSetReaderTheme _setTheme;
  final UCGetFontScale _getFontScale;
  final UCSetFontScale _setFontScale;

  /// Allowed text-size range; mirrors the data layer's clamp.
  ///
  /// The range runs past the printed page's own size on purpose: above
  /// `kBigTextThreshold` the reader stops reproducing the printed line breaks
  /// and reflows the page as one stream, which is what makes the large end of
  /// the range readable instead of a page of stranded words.
  static const double minScale = 0.8;
  static const double maxScale = 2.0;

  /// Slider steps over [minScale]…[maxScale] — 0.2 apart, so 1.0 (the printed
  /// size) lands exactly on a step and 1.6 is the first reflowed one.
  static const int scaleDivisions = 6;

  Future<void> load() async {
    final mode = await _getFontMode();
    mode.fold((_) {}, (m) => emit(state.copyWith(fontMode: m)));
    final theme = await _getTheme();
    theme.fold((_) {}, (t) => emit(state.copyWith(theme: t)));
    final scale = await _getFontScale();
    scale.fold((_) {}, (s) => emit(state.copyWith(fontScale: s)));
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
}
