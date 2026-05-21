import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';

abstract class RReciter {
  Future<Either<Failure, List<MReciter>>> getReciters();
  Future<Either<Failure, MReciter>> getActive();
  Future<Either<Failure, void>> setActive(String reciterId);
}
