import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';

class UCGetStorageSummary {
  UCGetStorageSummary(this._repo);
  final RDownloads _repo;

  Future<Either<Failure, int>> call() => _repo.totalBytes();
}
