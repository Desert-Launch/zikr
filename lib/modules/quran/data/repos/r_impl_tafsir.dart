import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_tafsir.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_tafsir.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_entry.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

class RImplTafsir implements RTafsir {
  RImplTafsir(this._local, this._remote);
  final DSLocalTafsir _local;
  final DSRemoteTafsir _remote;

  /// A `text` value shaped like `2:255` is a pointer to another ayah's entry
  /// (tafsir often covers a range of ayat as one block).
  static final RegExp _pointer = RegExp(r'^\d+:\d+$');

  @override
  Future<Either<Failure, List<ETafsirBook>>> catalog() async {
    try {
      return const Right(TafsirCatalog.books);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplTafsir.catalog', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> downloadedIds() async {
    try {
      return Right(_local.downloadedIds());
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplTafsir.downloadedIds', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> download(
    ETafsirBook book, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (_local.isDownloaded(book.id)) {
        onProgress?.call(1.0);
        return const Right(null);
      }
      // Reserve the last slice of the bar for the local write/parse step.
      final jsonString = await _remote.download(
        book.fullPath,
        onProgress: (p) => onProgress?.call(p * 0.95),
      );
      await _local.saveBook(book.id, jsonString);
      onProgress?.call(1.0);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplTafsir.download', error: e, stackTrace: st);
      return Left(Failure.serverFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(ETafsirBook book) async {
    try {
      await _local.deleteBook(book.id);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplTafsir.delete', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ETafsirEntry>>> getForAyah(ParamAyahRef ref) async {
    try {
      final downloaded = _local.downloadedIds().toSet();
      final entries = <ETafsirEntry>[];
      // Catalogue order keeps a stable tab order across books.
      for (final book in TafsirCatalog.books) {
        if (!downloaded.contains(book.id)) continue;
        final map = _local.bookMap(book.id);
        if (map == null) continue;
        final resolved = _resolve(map, ref.key);
        if (resolved == null) continue;
        entries.add(ETafsirEntry(
          book: book,
          html: resolved.text,
          linkedFromKey: resolved.linkedFrom,
        ));
      }
      return Right(entries);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplTafsir.getForAyah', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  /// Resolves the commentary text for [key], following up to a few range
  /// pointers. Returns null when the ayah has no entry or the text is empty.
  ({String text, String? linkedFrom})? _resolve(Map<String, dynamic> map, String key) {
    String current = key;
    String? linkedFrom;
    for (var hop = 0; hop < 5; hop++) {
      final node = map[current];
      final text = node is Map ? node['text'] as String? : null;
      if (text == null || text.isEmpty) return null;
      if (_pointer.hasMatch(text.trim())) {
        linkedFrom = text.trim();
        current = linkedFrom;
        continue;
      }
      return (text: text, linkedFrom: linkedFrom);
    }
    return null;
  }
}
