import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Disk-truth download status for all 114 surahs, keyed by surah number.
class UCGetAllSurahsStatus {
  UCGetAllSurahsStatus(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, Map<int, SurahDownloadInfo>>> call(String reciterId) =>
      _repo.allSurahsInfo(reciterId);
}
