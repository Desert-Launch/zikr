import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_ayah_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_downloaded_tafsirs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_selected_tafsir.dart';
import 'package:quran/modules/quran/presentation/cubits/s_tafsir.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// Loads every downloaded book's commentary for a single ayah, and which of
/// them the viewer should open on.
class CBTafsir extends Cubit<STafsir> {
  CBTafsir(this._getTafsir, this._getDownloaded, this._getSelected)
      : super(const STafsir());

  final UCGetAyahTafsir _getTafsir;
  final UCGetDownloadedTafsirs _getDownloaded;
  final UCGetSelectedTafsir _getSelected;

  Future<void> load(ParamAyahRef ref) async {
    emit(state.copyWith(status: LoadStatus.loading, ref: ref, clearError: true));

    final downloaded = await _getDownloaded();
    final hasBooks = downloaded.fold((_) => false, (ids) => ids.isNotEmpty);
    final selected =
        (await _getSelected()).fold<String?>((_) => null, (id) => id);

    final result = await _getTafsir(ref);
    result.fold(
      (failure) => emit(state.copyWith(
        status: LoadStatus.error,
        hasBooks: hasBooks,
        selectedBookId: selected,
        clearSelectedBook: selected == null,
        error: failure.message,
      )),
      (entries) => emit(state.copyWith(
        status: LoadStatus.success,
        hasBooks: hasBooks,
        entries: entries,
        selectedBookId: selected,
        clearSelectedBook: selected == null,
      )),
    );
  }
}
