import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';

class UCCancelDownload {
  UCCancelDownload(this._repo);
  final RDownloads _repo;

  Future<Either<Failure, void>> call(String taskId) => _repo.cancel(taskId);
}
