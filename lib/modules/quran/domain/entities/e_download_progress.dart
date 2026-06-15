import 'package:equatable/equatable.dart';

/// Progress of an in-flight single-surah download.
///
/// [skipped] is the count of ayat that were already on disk before this run
/// started, so the surah is finished when `downloaded + skipped >= total`.
class SurahDownloadProgress extends Equatable {
  const SurahDownloadProgress({
    required this.surahNumber,
    required this.downloaded,
    required this.total,
    required this.skipped,
    this.error,
  });

  final int surahNumber;
  final int downloaded;
  final int total;
  final int skipped;
  final String? error;

  double get fraction =>
      total <= 0 ? 1.0 : ((downloaded + skipped) / total).clamp(0.0, 1.0);
  bool get isDone => downloaded + skipped >= total;

  /// Ayat present on disk right now (already-there + freshly downloaded).
  int get onDisk => downloaded + skipped;

  SurahDownloadProgress copyWith({
    int? downloaded,
    int? skipped,
    String? error,
    bool clearError = false,
  }) {
    return SurahDownloadProgress(
      surahNumber: surahNumber,
      downloaded: downloaded ?? this.downloaded,
      total: total,
      skipped: skipped ?? this.skipped,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [surahNumber, downloaded, total, skipped, error];
}

/// Progress of a "download all surahs" run — wraps the current surah's progress.
class AllSurahsDownloadProgress extends Equatable {
  const AllSurahsDownloadProgress({
    required this.currentSurah,
    required this.currentSurahProgress,
    required this.completedSurahs,
  });

  final int currentSurah;
  final SurahDownloadProgress currentSurahProgress;

  /// How many surahs have finished so far (0..114).
  final int completedSurahs;

  double get overallFraction => (completedSurahs / 114).clamp(0.0, 1.0);

  @override
  List<Object?> get props =>
      [currentSurah, currentSurahProgress, completedSurahs];
}

/// Per-reciter aggregate, computed from disk. Shown on the reciter cards.
class ReciterStats extends Equatable {
  const ReciterStats({
    required this.downloadedSurahs,
    required this.totalSurahs,
    required this.totalBytes,
  });

  const ReciterStats.empty()
    : downloadedSurahs = 0,
      totalSurahs = 114,
      totalBytes = 0;

  /// Surahs that are *fully* downloaded.
  final int downloadedSurahs;
  final int totalSurahs;
  final int totalBytes;

  bool get hasDownloads => totalBytes > 0 || downloadedSurahs > 0;
  double get megabytes => totalBytes / 1024 / 1024;

  @override
  List<Object?> get props => [downloadedSurahs, totalSurahs, totalBytes];
}
