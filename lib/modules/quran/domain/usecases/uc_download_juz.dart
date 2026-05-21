import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/domain/entities/param_download_request.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';

class UCDownloadJuz {
  UCDownloadJuz(this._repo);
  final RDownloads _repo;

  Future<Either<Failure, MDownloadTask>> call({
    required String reciterId,
    required int juz,
  }) {
    return _repo.start(ParamDownloadRequest.juz(reciterId: reciterId, juz: juz));
  }
}
