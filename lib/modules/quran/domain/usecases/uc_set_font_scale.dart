import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCSetFontScale {
  UCSetFontScale(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, void>> call(double scale) => _repo.setFontScale(scale);
}
