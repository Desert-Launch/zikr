import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCGetFontBold {
  UCGetFontBold(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, bool>> call() => _repo.getFontBold();
}
