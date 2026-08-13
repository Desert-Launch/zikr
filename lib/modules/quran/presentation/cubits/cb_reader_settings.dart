import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_bold.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_pinch_zoom.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_theme_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_bold.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_pinch_zoom.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_theme_mode.dart';
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
    this._getThemeMode,
    this._setThemeMode,
    this._getFontScale,
    this._setFontScale,
    this._getFontBold,
    this._setFontBold,
    this._getPinchZoom,
    this._setPinchZoom,
    this._getScrollMode,
    this._setScrollMode,
  ) : super(const SReaderSettings()) {
    load();
  }

  final UCGetFontMode _getFontMode;
  final UCSetFontMode _setFontMode;
  final UCGetReaderTheme _getTheme;
  final UCSetReaderTheme _setTheme;
  final UCGetReaderThemeMode _getThemeMode;
  final UCSetReaderThemeMode _setThemeMode;
  final UCGetFontScale _getFontScale;
  final UCSetFontScale _setFontScale;
  final UCGetFontBold _getFontBold;
  final UCSetFontBold _setFontBold;
  final UCGetPinchZoom _getPinchZoom;
  final UCSetPinchZoom _setPinchZoom;
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

  /// The device's current light/dark setting.
  ///
  /// Read straight off the platform dispatcher rather than a `MediaQuery`
  /// because this cubit is an app-wide singleton constructed outside the widget
  /// tree — it has no BuildContext. Live changes arrive through
  /// [applyPlatformBrightness], which the root widget's
  /// `didChangePlatformBrightness` calls.
  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  Future<void> load() async {
    final mode = await _getFontMode();
    mode.fold((_) {}, (m) => emit(state.copyWith(fontMode: m)));
    // The persisted page colour is only a fallback here: the mode decides, and
    // for `system` it recomputes from the device rather than trusting whatever
    // was last written (the user may have flipped dark mode while the app was
    // closed).
    final theme = await _getTheme();
    theme.fold((_) {}, (t) => emit(state.copyWith(theme: t)));
    final themeMode = await _getThemeMode();
    themeMode.fold(
      (_) {},
      (m) => emit(
        state.copyWith(themeMode: m, theme: m.resolve(_platformBrightness)),
      ),
    );
    final scale = await _getFontScale();
    scale.fold((_) {}, (s) => emit(state.copyWith(fontScale: s)));
    final bold = await _getFontBold();
    bold.fold((_) {}, (b) => emit(state.copyWith(bold: b)));
    final pinch = await _getPinchZoom();
    pinch.fold((_) {}, (p) => emit(state.copyWith(pinchZoom: p)));
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

  /// Pins a specific page colour, which also switches the mode off `system` —
  /// choosing a surface IS the override, so it must stop following the OS.
  Future<void> setTheme(ReaderTheme theme) =>
      setThemeMode(EReaderThemeModeX.pinning(theme));

  /// Sets the page-theme mode: `system` resumes following the device's
  /// light/dark setting, anything else pins that colour and ignores the OS.
  ///
  /// The resolved [ReaderTheme] is persisted alongside the mode so a cold start
  /// paints the right surface before [load] finishes, and so an install that
  /// later downgrades still finds a sensible page colour.
  Future<void> setThemeMode(EReaderThemeMode mode) async {
    final resolved = mode.resolve(_platformBrightness);
    if (mode == state.themeMode && resolved == state.theme) return;
    emit(state.copyWith(themeMode: mode, theme: resolved));
    await _setThemeMode(mode);
    await _setTheme(resolved);
  }

  /// Re-resolves the page colour after the device's light/dark setting changed.
  ///
  /// A no-op unless the user is on `system` — a pinned theme deliberately
  /// ignores the OS. The new colour is persisted so a cold start in the same
  /// brightness paints it immediately.
  Future<void> applyPlatformBrightness(Brightness brightness) async {
    if (state.themeMode != EReaderThemeMode.system) return;
    final resolved = state.themeMode.resolve(brightness);
    if (resolved == state.theme) return;
    emit(state.copyWith(theme: resolved));
    await _setTheme(resolved);
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    if (clamped == state.fontScale) return;
    emit(state.copyWith(fontScale: clamped));
    await _setFontScale(clamped);
  }

  /// Resizes the open reader WITHOUT persisting — the live half of a pinch.
  ///
  /// A pinch crosses many sizes on the way to the one the user means, and each
  /// is a real relayout of the cached pages. Doing the Hive write on every one
  /// of them buys nothing: only where the fingers lift is worth remembering,
  /// and [setFontScale] on release records it.
  void previewFontScale(double scale) {
    final clamped = scale.clamp(minScale, maxScale);
    if (clamped == state.fontScale) return;
    emit(state.copyWith(fontScale: clamped));
  }

  /// Persists the size a pinch settled on.
  ///
  /// Deliberately has NO "same value" guard, unlike [setFontScale]: by the time
  /// the fingers lift, [previewFontScale] has already emitted this exact value,
  /// so an equality check here would skip the single write of the whole gesture
  /// and the new size would be lost on the next launch.
  Future<void> commitFontScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    if (clamped != state.fontScale) emit(state.copyWith(fontScale: clamped));
    await _setFontScale(clamped);
  }

  /// Back to the printed size. Deliberately leaves [SReaderSettings.bold]
  /// alone — this resets the size control, not the whole text style.
  Future<void> resetFontScale() => setFontScale(defaultScale);

  /// Turns the two-finger pinch-to-resize gesture on the Mushaf on or off.
  Future<void> setPinchZoom(bool enabled) async {
    if (enabled == state.pinchZoom) return;
    emit(state.copyWith(pinchZoom: enabled));
    await _setPinchZoom(enabled);
  }

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
