import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

class UCSelectTafsir {
  UCSelectTafsir(this._repo);
  final RTafsir _repo;

  Future<Either<Failure, void>> call(String bookId) => _repo.selectBook(bookId);
}
