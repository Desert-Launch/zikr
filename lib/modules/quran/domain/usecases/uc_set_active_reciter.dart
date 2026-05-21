import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';

class UCSetActiveReciter {
  UCSetActiveReciter(this._repo);
  final RReciter _repo;

  Future<Either<Failure, void>> call(String reciterId) => _repo.setActive(reciterId);
}
