import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCSetReaderThemeMode {
  UCSetReaderThemeMode(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, void>> call(EReaderThemeMode mode) =>
      _repo.setThemeMode(mode);
}
