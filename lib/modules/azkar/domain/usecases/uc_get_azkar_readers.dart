import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// The adhkar-audio reader catalogue, whole or filtered to a dhikr/category.
class UCGetAzkarReaders {
  UCGetAzkarReaders(this._repo);
  final RAzkarAudio _repo;

  Future<Either<Failure, List<MAzkarReader>>> call() => _repo.readers();

  /// Only readers that actually recite this dhikr — the reader picker must not
  /// offer a voice that has nothing to play.
  Future<Either<Failure, List<MAzkarReader>>> forAdhkar(String adhkarId) =>
      _repo.readersForAdhkar(adhkarId);

  Future<Either<Failure, List<MAzkarReader>>> forCategory(String categoryId) =>
      _repo.readersForCategory(categoryId);
}
