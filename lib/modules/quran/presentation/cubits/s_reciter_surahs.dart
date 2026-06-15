import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SReciterSurahs extends Equatable {
  const SReciterSurahs({
    this.reciterId = '',
    this.status = LoadStatus.idle,
    this.surahs = const <MSurah>[],
    this.infoBySurah = const <int, SurahDownloadInfo>{},
    this.progressBySurah = const <int, SurahDownloadProgress>{},
    this.stats,
    this.isDownloadingAll = false,
    this.allCurrentSurah = 0,
    this.error,
  });

  final String reciterId;
  final LoadStatus status;
  final List<MSurah> surahs;

  /// Disk-truth status per surah number (from the last scan).
  final Map<int, SurahDownloadInfo> infoBySurah;

  /// Live progress for surahs that are currently downloading.
  final Map<int, SurahDownloadProgress> progressBySurah;

  /// Aggregate reciter stats for the header (complete surahs + bytes).
  final ReciterStats? stats;

  final bool isDownloadingAll;
  final int allCurrentSurah;
  final String? error;

  bool isDownloading(int surah) => progressBySurah.containsKey(surah);

  SReciterSurahs copyWith({
    String? reciterId,
    LoadStatus? status,
    List<MSurah>? surahs,
    Map<int, SurahDownloadInfo>? infoBySurah,
    Map<int, SurahDownloadProgress>? progressBySurah,
    ReciterStats? stats,
    bool? isDownloadingAll,
    int? allCurrentSurah,
    String? error,
    bool clearError = false,
  }) {
    return SReciterSurahs(
      reciterId: reciterId ?? this.reciterId,
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      infoBySurah: infoBySurah ?? this.infoBySurah,
      progressBySurah: progressBySurah ?? this.progressBySurah,
      stats: stats ?? this.stats,
      isDownloadingAll: isDownloadingAll ?? this.isDownloadingAll,
      allCurrentSurah: allCurrentSurah ?? this.allCurrentSurah,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    reciterId,
    status,
    surahs,
    infoBySurah,
    progressBySurah,
    stats,
    isDownloadingAll,
    allCurrentSurah,
    error,
  ];
}
