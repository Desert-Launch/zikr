import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Downloads all 114 surahs for a reciter, skipping files already on disk.
class UCDownloadAllSurahs {
  UCDownloadAllSurahs(this._repo);
  final RAudioDownloads _repo;

  Stream<AllSurahsDownloadProgress> call(String reciterId) =>
      _repo.downloadAllSurahs(reciterId);
}
