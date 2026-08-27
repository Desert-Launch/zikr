import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_number_search.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

/// Resolves a number the reader typed into the three things it can name in the
/// mushaf: a page, a surah and a hizb (offered as its four arba').
class UCNumberLookup {
  UCNumberLookup(this._repo);
  final RQuran _repo;

  Future<Either<Failure, ENumberSearch>> call(int number) => _repo.numberLookup(number);
}
