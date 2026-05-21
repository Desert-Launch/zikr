import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class UCGetSurahList {
  UCGetSurahList(this._repo);
  final RQuran _repo;

  Future<Either<Failure, List<MSurah>>> call() => _repo.getSurahs();
}
