import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';

class UCFetchAdhanCatalog {
  UCFetchAdhanCatalog(this._repo);
  final RAdhan _repo;

  Future<Either<Failure, List<MAdhan>>> call() => _repo.fetchCatalog();
}
