import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';

class UCGetCalculationMethods {
  UCGetCalculationMethods(this._repo);
  final RPrayer _repo;

  Future<Either<Failure, List<ECalculationMethod>>> call() =>
      _repo.getCalculationMethods();
}
