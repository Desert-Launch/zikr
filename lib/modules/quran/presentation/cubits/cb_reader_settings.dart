import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_mode.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// App-wide reader display settings.
///
/// Registered as a SINGLETON so the settings screen and any open Mushaf reader
/// share one instance — changing the font mode re-renders the reader instantly
/// (the renderer listens via `BlocSelector`). Loads the persisted mode once on
/// creation; the box is opened in `main()` before the first frame.
class CBReaderSettings extends Cubit<SReaderSettings> {
  CBReaderSettings(this._getFontMode, this._setFontMode)
      : super(const SReaderSettings()) {
    load();
  }

  final UCGetFontMode _getFontMode;
  final UCSetFontMode _setFontMode;

  Future<void> load() async {
    final result = await _getFontMode();
    result.fold(
      (_) {},
      (mode) => emit(state.copyWith(fontMode: mode)),
    );
  }

  Future<void> setFontMode(EQuranFontMode mode) async {
    if (mode == state.fontMode) return;
    // Optimistic: emit first so the open reader re-renders immediately, then
    // persist (best-effort — the next change retries).
    emit(state.copyWith(fontMode: mode));
    await _setFontMode(mode);
  }
}
