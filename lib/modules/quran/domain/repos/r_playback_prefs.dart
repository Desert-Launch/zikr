import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';

/// Persisted audio-player preferences (the durable subset of
/// [EPlaybackOptions]: speed, repeat mode/count, after-repeat, auto-advance).
abstract class RPlaybackPrefs {
  Future<Either<Failure, EPlaybackOptions>> getOptions();
  Future<Either<Failure, void>> saveOptions(EPlaybackOptions options);
}
