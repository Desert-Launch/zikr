import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';

class UCGetReciters {
  UCGetReciters(this._repo);
  final RReciter _repo;

  Future<Either<Failure, List<MReciter>>> call() => _repo.getReciters();
  Future<Either<Failure, MReciter>> active() => _repo.getActive();
}
