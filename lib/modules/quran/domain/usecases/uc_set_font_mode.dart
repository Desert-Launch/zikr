import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCSetFontMode {
  UCSetFontMode(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, void>> call(EQuranFontMode mode) =>
      _repo.setFontMode(mode);
}
