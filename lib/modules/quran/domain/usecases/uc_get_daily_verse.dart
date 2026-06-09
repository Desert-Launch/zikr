import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class UCGetDailyVerse {
  UCGetDailyVerse(this._repo);
  final RQuran _repo;

  Future<Either<Failure, EDailyVerse>> call(DateTime day) =>
      _repo.getDailyVerse(day);
}
