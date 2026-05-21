import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';

class UCResolveAudioUrl {
  UCResolveAudioUrl(this._repo);
  final RAudio _repo;

  Future<Either<Failure, String>> call({
    required String reciterId,
    required ParamAyahRef ref,
  }) {
    return _repo.resolveAyahAudio(reciterId: reciterId, surah: ref.surah, ayah: ref.ayah);
  }
}
