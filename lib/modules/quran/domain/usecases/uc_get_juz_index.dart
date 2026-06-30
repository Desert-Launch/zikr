import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class UCGetJuzIndex {
  UCGetJuzIndex(this._repo);
  final RQuran _repo;

  Future<Either<Failure, List<EJuzEntry>>> call() => _repo.getJuzIndex();
}
