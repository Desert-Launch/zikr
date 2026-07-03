import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

class UCDeleteTafsir {
  UCDeleteTafsir(this._repo);
  final RTafsir _repo;

  Future<Either<Failure, void>> call(ETafsirBook book) => _repo.delete(book);
}
