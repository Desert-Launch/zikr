import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_downloaded_tafsirs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_tafsir_catalog.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/cubits/s_tafsir_library.dart';

/// Drives the tafsir library: lists the catalogue and manages per-book
/// downloads and deletions with live progress.
class CBTafsirLibrary extends Cubit<STafsirLibrary> {
  CBTafsirLibrary({
    required UCGetTafsirCatalog catalog,
    required UCGetDownloadedTafsirs downloaded,
    required UCDownloadTafsir download,
    required UCDeleteTafsir delete,
  })  : _catalog = catalog,
        _downloaded = downloaded,
        _download = download,
        _delete = delete,
        super(const STafsirLibrary());

  final UCGetTafsirCatalog _catalog;
  final UCGetDownloadedTafsirs _downloaded;
  final UCDownloadTafsir _download;
  final UCDeleteTafsir _delete;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final catalogRes = await _catalog();
    final downloadedRes = await _downloaded();

    catalogRes.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (books) {
        final ids = downloadedRes.fold((_) => <String>{}, (list) => list.toSet());
        emit(state.copyWith(status: LoadStatus.success, books: books, downloaded: ids));
      },
    );
  }

  Future<void> downloadBook(ETafsirBook book) async {
    if (state.isDownloading(book.id) || state.isDownloaded(book.id)) return;
    _setProgress(book.id, 0);

    final result = await _download(
      book,
      onProgress: (p) => _setProgress(book.id, p),
    );

    result.fold(
      (failure) {
        _clearProgress(book.id);
        emit(state.copyWith(error: failure.message));
      },
      (_) {
        _clearProgress(book.id);
        emit(state.copyWith(downloaded: {...state.downloaded, book.id}));
      },
    );
  }

  Future<void> deleteBook(ETafsirBook book) async {
    final result = await _delete(book);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final next = {...state.downloaded}..remove(book.id);
        emit(state.copyWith(downloaded: next));
      },
    );
  }

  void _setProgress(String id, double value) {
    emit(state.copyWith(progress: {...state.progress, id: value}));
  }

  void _clearProgress(String id) {
    final next = {...state.progress}..remove(id);
    emit(state.copyWith(progress: next));
  }
}
