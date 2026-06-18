import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_playback_prefs.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/repos/r_playback_prefs.dart';

class RImplPlaybackPrefs implements RPlaybackPrefs {
  RImplPlaybackPrefs(this._local);
  final DSLocalPlaybackPrefs _local;

  @override
  Future<Either<Failure, EPlaybackOptions>> getOptions() async {
    try {
      return Right(_local.getOptions());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPlaybackPrefs.getOptions',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveOptions(EPlaybackOptions options) async {
    try {
      await _local.setOptions(options);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPlaybackPrefs.saveOptions',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
