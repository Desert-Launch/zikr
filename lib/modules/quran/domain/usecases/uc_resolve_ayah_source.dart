import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_audio_source.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';

/// Resolves the playable source for an ayah offline-first: a local file when the
/// ayah is on disk, otherwise a remote CDN URL to stream immediately.
class UCResolveAyahSource {
  UCResolveAyahSource(this._repo);
  final RAudioDownloads _repo;

  Future<Either<Failure, EAyahAudioSource>> call(
    ParamAyahRef ref,
    String reciterId,
  ) => _repo.resolveAyahSource(reciterId, ref.surah, ref.ayah);
}
