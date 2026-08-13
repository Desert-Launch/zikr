import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reader_settings.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';
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

  @override
  Future<Either<Failure, ReaderTheme>> getTheme() async {
    try {
      return Right(_local.getTheme());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getTheme',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTheme(ReaderTheme theme) async {
    try {
      await _local.setTheme(theme);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setTheme',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EReaderThemeMode>> getThemeMode() async {
    try {
      return Right(_local.getThemeMode());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getThemeMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setThemeMode(EReaderThemeMode mode) async {
    try {
      await _local.setThemeMode(mode);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setThemeMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getFontScale() async {
    try {
      return Right(_local.getFontScale());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getFontScale',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFontScale(double scale) async {
    try {
      await _local.setFontScale(scale);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setFontScale',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getPinchZoom() async {
    try {
      return Right(_local.getPinchZoom());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getPinchZoom',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setPinchZoom(bool enabled) async {
    try {
      await _local.setPinchZoom(enabled);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setPinchZoom',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getFontBold() async {
    try {
      return Right(_local.getFontBold());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getFontBold',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFontBold(bool bold) async {
    try {
      await _local.setFontBold(bold);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setFontBold',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EReaderScrollMode>> getScrollMode() async {
    try {
      return Right(_local.getScrollMode());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.getScrollMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setScrollMode(EReaderScrollMode mode) async {
    try {
      await _local.setScrollMode(mode);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplReaderSettings.setScrollMode',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
