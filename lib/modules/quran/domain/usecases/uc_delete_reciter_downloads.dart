import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Deletes every downloaded file for a reciter.
class UCDeleteReciterDownloads {
  UCDeleteReciterDownloads(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, void>> call(String reciterId) =>
      _repo.deleteReciter(reciterId);
}
