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

  /// Removes a previously downloaded book from local storage.
  Future<Either<Failure, void>> delete(ETafsirBook book);

  /// All downloaded books' commentary for [ref], in catalogue order.
  Future<Either<Failure, List<ETafsirEntry>>> getForAyah(ParamAyahRef ref);
}
