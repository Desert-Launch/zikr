import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/ayah_counts.dart';
import 'package:quran/modules/quran/domain/entities/e_share_format.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/entities/param_share_range.dart';
import 'package:quran/modules/quran/domain/usecases/uc_build_ayah_share.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_tafsir.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_downloaded_tafsirs.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

/// Drives the share sheet: holds the reader's choices and keeps a resolved
/// [EAyahShare] in step with them.
///
/// Every choice that changes what would be sent re-resolves, so the preview in
/// the sheet is always the thing the share button will actually produce.
class CBAyahShare extends Cubit<SAyahShare> {
  CBAyahShare(this._build, this._downloaded, this._download)
    : super(const SAyahShare());

  final UCBuildAyahShare _build;
  final UCGetDownloadedTafsirs _downloaded;
  final UCDownloadTafsir _download;

  /// Guards against an older resolve landing after a newer one — the reader can
  /// spin the range wheel faster than the mushaf pages can be read.
  int _resolveId = 0;

  /// Holds off resolving while the range wheel is still turning. Every notch
  /// the wheel passes is a range in its own right, and resolving each one
  /// would read the mushaf a dozen times over on the way to the verse the
  /// reader actually stopped on.
  Timer? _settle;
  static const Duration _settleDelay = Duration(milliseconds: 180);

  /// Opens the sheet on [ref]: one verse, no books, badge on.
  Future<void> open(ParamAyahRef ref) async {
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        surah: ref.surah,
        from: ref.ayah,
        to: ref.ayah,
        ayahCount: AyahCounts.forSurah(ref.surah),
        bookIds: const [],
        clearEdge: true,
        clearError: true,
      ),
    );
    await _loadBooks();
    await _resolve();
  }

  void setFormat(EShareFormat format) {
    if (format == state.format) return;
    emit(state.copyWith(format: format));
  }

  void toggleAppBadge() => emit(state.copyWith(appBadge: !state.appBadge));

  /// Opens the wheel on one of the two range rows, or puts it away again when
  /// the row it is already on is tapped a second time.
  void setEdge(EShareRangeEdge edge) => emit(
    edge == state.edge
        ? state.copyWith(clearEdge: true)
        : state.copyWith(edge: edge),
  );

  /// Moves the edge the wheel is on. The range can never run backwards, so
  /// pulling `from` past `to` pushes `to` along with it, and vice versa.
  void setRangeValue(int ayah) {
    if (state.edge == null) return;
    final value = ayah.clamp(1, state.ayahCount);
    final from = state.edge == EShareRangeEdge.from
        ? value
        : (value < state.from ? value : state.from);
    final to = state.edge == EShareRangeEdge.to
        ? value
        : (value > state.to ? value : state.to);
    if (from == state.from && to == state.to) return;
    emit(state.copyWith(from: from, to: to, status: LoadStatus.loading));
    _settle?.cancel();
    _settle = Timer(_settleDelay, _resolve);
  }

  Future<void> addBook(ETafsirBook book) async {
    if (state.bookIds.contains(book.id)) return;
    emit(state.copyWith(bookIds: [...state.bookIds, book.id]));
    await _resolve();
  }

  /// Fetches a catalogue book the reader has not got yet and attaches it.
  ///
  /// Downloading from inside the share sheet rather than sending them to the
  /// library: they asked for this book, on this verse, and coming back to
  /// re-open the sheet and rebuild the range is a long way round.
  Future<bool> downloadAndAddBook(ETafsirBook book) async {
    if (state.isDownloading(book.id)) return false;
    if (state.isDownloaded(book.id)) {
      await addBook(book);
      return true;
    }
    _setProgress(book.id, 0);
    final result = await _download(
      book,
      onProgress: (progress) => _setProgress(book.id, progress),
    );
    if (isClosed) return false;
    _clearProgress(book.id);
    if (result.isLeft()) {
      emit(
        state.copyWith(
          error: result.fold((f) => f.message, (_) => null),
        ),
      );
      return false;
    }
    await _loadBooks();
    if (isClosed) return false;
    await addBook(book);
    return true;
  }

  /// Both guard [isClosed]: a download outlives the sheet that started it, and
  /// its progress callbacks keep arriving after the reader has dismissed
  /// everything — emitting on a closed cubit is an error, not a no-op.
  void _setProgress(String id, double value) {
    if (isClosed) return;
    emit(state.copyWith(downloads: {...state.downloads, id: value}));
  }

  void _clearProgress(String id) {
    if (isClosed) return;
    emit(state.copyWith(downloads: {...state.downloads}..remove(id)));
  }

  Future<void> removeBook(String bookId) async {
    if (!state.bookIds.contains(bookId)) return;
    emit(
      state.copyWith(
        bookIds: state.bookIds.where((id) => id != bookId).toList(),
      ),
    );
    await _resolve();
  }

  /// Reorders the attached books, which is the order they are printed in.
  Future<void> reorderBooks(int oldIndex, int newIndex) async {
    final ids = [...state.bookIds];
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    // ReorderableListView reports the target as an insertion index in the
    // *unchanged* list, so removing first shifts everything after it down one.
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    ids.insert(target.clamp(0, ids.length - 1), ids.removeAt(oldIndex));
    emit(state.copyWith(bookIds: ids));
    await _resolve();
  }

  /// Picks up books downloaded since the sheet was last opened, and drops any
  /// attached book that has been deleted from the library in the meantime.
  Future<void> _loadBooks() async {
    final result = await _downloaded();
    final ids = result.getOrElse(() => const []).toSet();
    final books = [
      for (final book in TafsirCatalog.books)
        if (ids.contains(book.id)) book,
    ];
    if (isClosed) return;
    emit(
      state.copyWith(
        availableBooks: books,
        bookIds: state.bookIds.where(ids.contains).toList(),
      ),
    );
  }

  @override
  Future<void> close() {
    _settle?.cancel();
    return super.close();
  }

  Future<void> _resolve() async {
    _settle?.cancel();
    final id = ++_resolveId;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final result = await _build(
      ParamShareRange(
        surah: state.surah,
        from: state.from,
        to: state.to,
        bookIds: state.bookIds,
      ),
    );
    if (isClosed || id != _resolveId) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: LoadStatus.error, error: failure.message),
      ),
      (content) =>
          emit(state.copyWith(status: LoadStatus.success, content: content)),
    );
  }
}
