import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_audio_source.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';

/// Offline-first audio download manager. Status is always derived from disk —
/// there is no persisted task table, so reported state can never drift.
abstract class RAudioDownloads {
  /// Ensures a single ayah's audio file exists at the canonical path,
  /// downloading it on demand. Returns the local file path.
  Future<Either<Failure, String>> ensureAyahFile(
    String reciterId,
    int surah,
    int ayah,
  );

  /// Resolves a *playable* source for a single ayah without blocking on a
  /// download: the local file when it is already on disk, otherwise the remote
  /// CDN URL to stream immediately. Used by the player so playback starts at
  /// once and each ayah independently prefers local audio when available.
  Future<Either<Failure, EAyahAudioSource>> resolveAyahSource(
    String reciterId,
    int surah,
    int ayah,
  );

  /// Downloads every ayah of [surah] that is not already on disk. Idempotent:
  /// re-invoking after a partial run only fetches the gaps. Emits progress as it
  /// goes and completes (closes) when the surah is fully on disk. Calling this
  /// for a surah that is already downloading returns the *same* live stream.
  Stream<SurahDownloadProgress> downloadSurah(String reciterId, int surah);

  /// Sequentially downloads all 114 surahs (joining any already in flight),
  /// skipping files already on disk. Best-effort: a failing surah is reported
  /// and the run continues to the next one.
  Stream<AllSurahsDownloadProgress> downloadAllSurahs(String reciterId);

  /// Disk-truth status for a single surah.
  Future<Either<Failure, SurahDownloadInfo>> surahInfo(
    String reciterId,
    int surah,
  );

  /// Disk-truth status for all 114 surahs, keyed by surah number.
  Future<Either<Failure, Map<int, SurahDownloadInfo>>> allSurahsInfo(
    String reciterId,
  );

  /// Aggregate stats for a reciter (complete surahs + bytes on disk).
  Future<Either<Failure, ReciterStats>> reciterStats(String reciterId);

  Future<Either<Failure, void>> deleteSurah(String reciterId, int surah);
  Future<Either<Failure, void>> deleteReciter(String reciterId);

  /// True when a download for (reciter, surah) is currently in flight.
  bool isSurahDownloading(String reciterId, int surah);

  /// Latest emitted progress for an in-flight surah download, or null.
  SurahDownloadProgress? activeProgress(String reciterId, int surah);

  /// Requests cancellation of a single in-flight surah download.
  void cancelSurah(String reciterId, int surah);

  /// Requests cancellation of all in-flight downloads (incl. download-all).
  void cancelAll();
}
