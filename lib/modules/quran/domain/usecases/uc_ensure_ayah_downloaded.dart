import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Ensures the given ayah's audio file exists locally (downloading on demand)
/// and returns its local file path.
class UCEnsureAyahDownloaded {
  UCEnsureAyahDownloaded(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, String>> call(ParamAyahRef ref, String reciterId) =>
      _repo.ensureAyahFile(reciterId, ref.surah, ref.ayah);
}
