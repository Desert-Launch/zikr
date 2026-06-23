import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';

/// Persisted reader display preferences (font mode, reading theme, text size).
abstract class RReaderSettings {
  Future<Either<Failure, EQuranFontMode>> getFontMode();
  Future<Either<Failure, void>> setFontMode(EQuranFontMode mode);

  Future<Either<Failure, ReaderTheme>> getTheme();
  Future<Either<Failure, void>> setTheme(ReaderTheme theme);

  Future<Either<Failure, double>> getFontScale();
  Future<Either<Failure, void>> setFontScale(double scale);
}
