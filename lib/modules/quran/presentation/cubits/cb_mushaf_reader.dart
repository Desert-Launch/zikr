import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_page_layout.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class CBMushafReader extends Cubit<SMushafReader> {
  CBMushafReader(this._getPage, this._saveLastRead, this._fonts)
      : super(const SMushafReader());

  final UCGetPageLayout _getPage;
  final UCSaveLastRead _saveLastRead;
  final DSQpcFontLoader _fonts;

  Timer? _saveDebounce;

  Future<void> openPage(int page) async {
    if (page < 1 || page > 604) return;
    emit(state.copyWith(currentPage: page, status: LoadStatus.loading));
    // Preload fonts in parallel with layout JSON fetch.
    final preloadFut = _fonts.preloadWindow(page);
    final layoutRes = await _getPage(page);
    await preloadFut;
    layoutRes.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (layout) => emit(state.copyWith(status: LoadStatus.success, layout: layout)),
    );
    _scheduleLastReadSave(page);
  }

  void selectAyah(ParamAyahRef ref) {
    if (state.selectedAyah?.key == ref.key) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedAyah: ref));
    }
  }

  void clearSelection() => emit(state.copyWith(clearSelected: true, multiSelection: const {}));

  void toggleMultiSelect(ParamAyahRef ref) {
    final next = Set<String>.from(state.multiSelection);
    if (!next.add(ref.key)) next.remove(ref.key);
    emit(state.copyWith(multiSelection: next));
  }

  void setTheme(ReaderTheme theme) => emit(state.copyWith(theme: theme));
  void setFontScale(double scale) =>
      emit(state.copyWith(fontScale: scale.clamp(0.8, 1.5)));

  void _scheduleLastReadSave(int page) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 5), () {
      final layout = state.layout;
      final first = layout?.allAyahRefs.firstOrNull;
      _saveLastRead(
        surah: first?.surah ?? 1,
        ayah: first?.ayah ?? 1,
        page: page,
      );
    });
  }

  @override
  Future<void> close() {
    _saveDebounce?.cancel();
    return super.close();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
