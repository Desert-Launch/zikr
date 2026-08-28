import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_downloaded_tafsirs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_selected_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_tafsir_catalog.dart';
import 'package:quran/modules/quran/domain/usecases/uc_select_tafsir.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/cubits/s_tafsir_library.dart';

/// Drives the tafsir library: lists the catalogue, manages per-book downloads
/// and deletions with live progress, and holds which book the per-ayah viewer
/// opens on.
class CBTafsirLibrary extends Cubit<STafsirLibrary> {
  CBTafsirLibrary({
    required UCGetTafsirCatalog catalog,
    required UCGetDownloadedTafsirs downloaded,
    required UCDownloadTafsir download,
    required UCDeleteTafsir delete,
    required UCGetSelectedTafsir selected,
    required UCSelectTafsir select,
  })  : _catalog = catalog,
        _downloaded = downloaded,
        _download = download,
        _delete = delete,
        _selected = selected,
        _select = select,
        super(const STafsirLibrary());

  final UCGetTafsirCatalog _catalog;
  final UCGetDownloadedTafsirs _downloaded;
  final UCDownloadTafsir _download;
  final UCDeleteTafsir _delete;
  final UCGetSelectedTafsir _selected;
  final UCSelectTafsir _select;

  Future<void> load() async {
    emit(state.copyWith(
      status: LoadStatus.loading,
      clearError: true,
      clearJustDownloaded: true,
    ));
    final catalogRes = await _catalog();
    final downloadedRes = await _downloaded();
    final selectedRes = await _selected();

    catalogRes.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (books) {
        final ids = downloadedRes.fold((_) => <String>{}, (list) => list.toSet());
        final selected = selectedRes.fold<String?>((_) => null, (id) => id);
        emit(state.copyWith(
          status: LoadStatus.success,
          books: books,
          downloaded: ids,
          selectedId: selected,
          clearSelected: selected == null,
        ));
      },
    );
  }

  /// Makes [book] the one the per-ayah viewer opens on. Only a downloaded book
  /// can be selected — the catalogue rows for the rest download instead.
  Future<void> selectBook(ETafsirBook book) async {
    if (!state.isDownloaded(book.id)) return;
    final result = await _select(book.id);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(selectedId: book.id)),
    );
  }

  /// Downloads [book] and, on success, makes it the selected one — a reader who
  /// went and fetched a book means to read it, so the viewer opens on it.
  Future<void> downloadBook(ETafsirBook book) async {
    if (state.isDownloading(book.id) || state.isDownloaded(book.id)) return;
    emit(state.copyWith(clearJustDownloaded: true, clearError: true));
    _setProgress(book.id, 0);

    final result = await _download(
      book,
      onProgress: (p) => _setProgress(book.id, p),
    );

    await result.fold(
      (failure) async {
        _clearProgress(book.id);
        emit(state.copyWith(error: failure.message));
      },
      (_) async {
        await _select(book.id);
        _clearProgress(book.id);
        emit(state.copyWith(
          downloaded: {...state.downloaded, book.id},
          selectedId: book.id,
          justDownloadedId: book.id,
        ));
      },
    );
  }

  Future<void> deleteBook(ETafsirBook book) async {
    final result = await _delete(book);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final next = {...state.downloaded}..remove(book.id);
        emit(state.copyWith(
          downloaded: next,
          // Deleting the selected book hands the viewer back to its default.
          clearSelected: state.isSelected(book.id),
        ));
      },
    );
  }

  /// Consumes the [STafsirLibrary.justDownloadedId] signal, so a rebuild does
  /// not toast (and leave) a second time.
  void acknowledgeDownload() {
    if (state.justDownloadedId == null) return;
    emit(state.copyWith(clearJustDownloaded: true));
  }

  void _setProgress(String id, double value) {
    emit(state.copyWith(progress: {...state.progress, id: value}));
  }

  void _clearProgress(String id) {
    final next = {...state.progress}..remove(id);
    emit(state.copyWith(progress: next));
  }
}
