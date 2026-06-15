import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Downloads every ayah of a surah that is not already on disk (idempotent).
/// Emits progress; the stream completes when the surah is fully downloaded.
class UCDownloadSurah {
  UCDownloadSurah(this._repo);
  final RAudioDownloads _repo;

  Stream<SurahDownloadProgress> call(String reciterId, int surah) =>
      _repo.downloadSurah(reciterId, surah);
}
