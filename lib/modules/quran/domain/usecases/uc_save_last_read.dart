import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';

class UCSaveLastRead {
  UCSaveLastRead(this._repo);
  final RBookmarks _repo;

  Future<Either<Failure, void>> call({
    required int surah,
    required int ayah,
    required int page,
  }) {
    return _repo.saveLastRead(MLastRead(
      surah: surah,
      ayah: ayah,
      page: page,
      updatedAt: DateTime.now(),
    ));
  }

  Future<Either<Failure, MLastRead?>> getLastRead() => _repo.getLastRead();
}
