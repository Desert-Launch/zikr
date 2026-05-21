import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/domain/entities/param_download_request.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';

class UCDownloadSurah {
  UCDownloadSurah(this._repo);
  final RDownloads _repo;

  Future<Either<Failure, MDownloadTask>> call({
    required String reciterId,
    required int surah,
  }) {
    return _repo.start(ParamDownloadRequest.surah(reciterId: reciterId, surah: surah));
  }
}
