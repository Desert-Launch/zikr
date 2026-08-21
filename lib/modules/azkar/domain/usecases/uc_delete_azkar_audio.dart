import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// Removes downloaded adhkar audio — one reader, one of its categories, or the
/// whole library.
class UCDeleteAzkarAudio {
  UCDeleteAzkarAudio(this._repo);
  final RAzkarAudio _repo;

  Future<Either<Failure, void>> reader(String readerId) =>
      _repo.deleteReader(readerId);

  Future<Either<Failure, void>> category(String readerId, String categoryId) =>
      _repo.deleteCategory(readerId, categoryId);

  Future<Either<Failure, void>> all() => _repo.deleteAll();
}
