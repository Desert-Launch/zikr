import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCGetFontMode {
  UCGetFontMode(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, EQuranFontMode>> call() => _repo.getFontMode();
}
