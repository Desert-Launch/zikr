import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Aggregate download stats for a reciter (complete surahs + bytes on disk).
class UCGetReciterStats {
  UCGetReciterStats(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, ReciterStats>> call(String reciterId) =>
      _repo.reciterStats(reciterId);
}
