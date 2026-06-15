import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Deletes all downloaded ayat of a surah for a reciter.
class UCDeleteSurahDownload {
  UCDeleteSurahDownload(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, void>> call(String reciterId, int surah) =>
      _repo.deleteSurah(reciterId, surah);
}
