import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';

class UCSetReaderScrollMode {
  UCSetReaderScrollMode(this._repo);
  final RReaderSettings _repo;

  Future<Either<Failure, void>> call(EReaderScrollMode mode) =>
      _repo.setScrollMode(mode);
}
