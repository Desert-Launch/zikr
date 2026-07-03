import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

class UCGetTafsirCatalog {
  UCGetTafsirCatalog(this._repo);
  final RTafsir _repo;

  Future<Either<Failure, List<ETafsirBook>>> call() => _repo.catalog();
}
