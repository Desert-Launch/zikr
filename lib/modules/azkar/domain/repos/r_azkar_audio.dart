import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';

/// The adhkar audio layer: catalogue, playback resolution, downloads, storage.
///
/// It never reads or writes the adhkar themselves — every method is keyed by an
/// existing `MAzkarItem.id` or category id, so the audio feature can be removed
/// entirely without touching a single dhikr.
abstract class RAzkarAudio {
  /// Readers that are verified and carry at least one recording.
  Future<Either<Failure, List<MAzkarReader>>> readers();

  /// Readers that have a recording of this particular dhikr — the only ones the
  /// reader picker may offer for it.
  Future<Either<Failure, List<MAzkarReader>>> readersForAdhkar(String adhkarId);

  /// Readers with a whole-sitting recording of this category.
  Future<Either<Failure, List<MAzkarReader>>> readersForCategory(
    String categoryId,
  );

  /// Resolves what to play for one dhikr, following the fallback ladder.
  /// [forceReaderId] pins a reader for this call only (the in-player picker).
  Future<Either<Failure, EAzkarAudioSource>> resolveAdhkar(
    String adhkarId, {
    String? forceReaderId,
  });

  /// Resolves the whole-sitting recording for a category.
  Future<Either<Failure, EAzkarAudioSource>> resolveCategory(
    String categoryId, {
    String? forceReaderId,
  });

  /// Disk + manifest summary for one reader.
  Future<Either<Failure, AzkarReaderStats>> readerStats(String readerId);

  /// Summary for every reader, for the download manager list.
  Future<Either<Failure, Map<String, AzkarReaderStats>>> allReaderStats();

  /// Per-category breakdown of a reader's pack, for the reader detail screen.
  Future<Either<Failure, List<AzkarCategoryAudioInfo>>> categoryBreakdown(
    String readerId,
  );

  /// Downloads a reader's pack, or just one category of it when [categoryId] is
  /// given. Idempotent: files already on disk are skipped and a partial file is
  /// resumed. Calling it for a run already in flight returns the *same* stream.
  Stream<AzkarPackProgress> download(String readerId, {String? categoryId});

  Future<Either<Failure, void>> deleteReader(String readerId);

  Future<Either<Failure, void>> deleteCategory(
    String readerId,
    String categoryId,
  );

  Future<Either<Failure, void>> deleteAll();

  Future<Either<Failure, AzkarStorageUsage>> storageUsage();

  /// Walks the persisted download table against the filesystem and repairs any
  /// record that disagrees with it (file deleted by the OS, transfer killed
  /// mid-flight). Run once at startup.
  Future<Either<Failure, int>> reconcile();

  /// The globally preferred reader, or null when the user has not picked one.
  String? get preferredReaderId;

  Future<Either<Failure, void>> setPreferredReader(String? readerId);

  bool isDownloading(String readerId);

  AzkarPackProgress? activeProgress(String readerId);

  /// Requests cancellation of an in-flight run. Partial files are kept so a
  /// later run resumes rather than restarts.
  void cancel(String readerId);

  void cancelAll();
}
