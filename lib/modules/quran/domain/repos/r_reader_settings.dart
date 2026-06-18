import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';

/// Persisted reader display preferences (currently the Quran font mode).
abstract class RReaderSettings {
  Future<Either<Failure, EQuranFontMode>> getFontMode();
  Future<Either<Failure, void>> setFontMode(EQuranFontMode mode);
}
