import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// Reads and writes the globally preferred adhkar reader.
class UCSetPreferredAzkarReader {
  UCSetPreferredAzkarReader(this._repo);
  final RAzkarAudio _repo;

  String? get current => _repo.preferredReaderId;

  Future<Either<Failure, void>> call(String? readerId) =>
      _repo.setPreferredReader(readerId);
}
