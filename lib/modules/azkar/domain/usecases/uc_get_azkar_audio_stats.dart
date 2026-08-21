import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// Disk + manifest figures behind the download manager's counts.
class UCGetAzkarAudioStats {
  UCGetAzkarAudioStats(this._repo);
  final RAzkarAudio _repo;

  Future<Either<Failure, Map<String, AzkarReaderStats>>> call() =>
      _repo.allReaderStats();

  Future<Either<Failure, AzkarReaderStats>> forReader(String readerId) =>
      _repo.readerStats(readerId);

  Future<Either<Failure, List<AzkarCategoryAudioInfo>>> categories(
    String readerId,
  ) => _repo.categoryBreakdown(readerId);

  Future<Either<Failure, AzkarStorageUsage>> storage() => _repo.storageUsage();

  /// Repairs download records that disagree with the filesystem. Run at boot.
  Future<Either<Failure, int>> reconcile() => _repo.reconcile();
}
