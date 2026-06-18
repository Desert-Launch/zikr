import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/repos/r_playback_prefs.dart';

class UCSavePlaybackPrefs {
  UCSavePlaybackPrefs(this._repo);
  final RPlaybackPrefs _repo;

  Future<Either<Failure, void>> call(EPlaybackOptions options) =>
      _repo.saveOptions(options);
}
