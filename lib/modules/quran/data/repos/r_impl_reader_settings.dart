import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reader_settings.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class RImplReaderSettings implements RReaderSettings {
  RImplReaderSettings(this._local);
  final DSLocalReaderSettings _local;

  @override
  Future<Either<Failure, EQuranFontMode>> getFontMode() async {
    try {
      return Right(_local.getFontMode());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getFontMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFontMode(EQuranFontMode mode) async {
    try {
      await _local.setFontMode(mode);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setFontMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
