import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_entry.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Tafsir (Quran commentary) catalogue, downloads and per-ayah lookup.
abstract class RTafsir {
  /// The shipped catalogue of downloadable books.
  Future<Either<Failure, List<ETafsirBook>>> catalog();

  /// Ids of books already downloaded and stored locally.
  Future<Either<Failure, List<String>>> downloadedIds();

  /// Downloads [book] from QUL, decodes it and stores it locally.
  /// [onProgress] reports 0.0–1.0 across download + processing.
  Future<Either<Failure, void>> download(
    ETafsirBook book, {
    void Function(double progress)? onProgress,
  });

  /// Id of the book the per-ayah viewer opens on, or null when the reader has
  /// not picked one — the viewer then falls back to
  /// [TafsirCatalog.defaultBookId].
  Future<Either<Failure, String?>> selectedBookId();

  /// Makes [bookId] the book the viewer opens on.
  Future<Either<Failure, void>> selectBook(String bookId);

  /// Removes a previously downloaded book from local storage.
  Future<Either<Failure, void>> delete(ETafsirBook book);

  /// Fetches [TafsirCatalog.defaultBook] once, so a fresh install has a tafsir
  /// to show without a trip to the library. Resolves to whether this call
  /// actually downloaded anything: false when the seed already ran, when the
  /// book was there already, or when it was deleted on purpose.
  Future<Either<Failure, bool>> seedDefaultBook();

  /// All downloaded books' commentary for [ref], in catalogue order.
  Future<Either<Failure, List<ETafsirEntry>>> getForAyah(ParamAyahRef ref);
}
