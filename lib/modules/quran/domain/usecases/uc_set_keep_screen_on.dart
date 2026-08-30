import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCSetKeepScreenOn {
  UCSetKeepScreenOn(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, void>> call(bool enabled) =>
      _repo.setKeepScreenOn(enabled);
}
