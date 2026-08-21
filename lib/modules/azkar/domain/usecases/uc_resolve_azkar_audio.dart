import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// Decides what to play for a dhikr or a whole sitting, following the
/// preferred-reader → downloaded → streamed ladder.
class UCResolveAzkarAudio {
  UCResolveAzkarAudio(this._repo);
  final RAzkarAudio _repo;

  Future<Either<Failure, EAzkarAudioSource>> call(
    String adhkarId, {
    String? forceReaderId,
  }) => _repo.resolveAdhkar(adhkarId, forceReaderId: forceReaderId);

  Future<Either<Failure, EAzkarAudioSource>> category(
    String categoryId, {
    String? forceReaderId,
  }) => _repo.resolveCategory(categoryId, forceReaderId: forceReaderId);
}
