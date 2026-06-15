import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Disk-truth download status for a single surah.
class UCGetSurahStatus {
  UCGetSurahStatus(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, SurahDownloadInfo>> call(String reciterId, int surah) =>
      _repo.surahInfo(reciterId, surah);
}
