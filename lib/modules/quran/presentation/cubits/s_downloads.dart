import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

enum DownloadGroupBy { surah, juz }

class SDownloads extends Equatable {
  const SDownloads({
    this.status = LoadStatus.idle,
    this.reciters = const <MReciter>[],
    this.activeReciterId,
    this.surahs = const <MSurah>[],
    this.tasks = const <String, MDownloadTask>{},
    this.groupBy = DownloadGroupBy.surah,
    this.totalBytes = 0,
    this.error,
  });

  final LoadStatus status;
  final List<MReciter> reciters;
  final String? activeReciterId;
  final List<MSurah> surahs;
  /// Keyed by task id ("alafasy_surah_1", "alafasy_juz_30").
  final Map<String, MDownloadTask> tasks;
  final DownloadGroupBy groupBy;
  final int totalBytes;
  final String? error;

  SDownloads copyWith({
    LoadStatus? status,
    List<MReciter>? reciters,
    String? activeReciterId,
    List<MSurah>? surahs,
    Map<String, MDownloadTask>? tasks,
    DownloadGroupBy? groupBy,
    int? totalBytes,
    String? error,
  }) {
    return SDownloads(
      status: status ?? this.status,
      reciters: reciters ?? this.reciters,
      activeReciterId: activeReciterId ?? this.activeReciterId,
      surahs: surahs ?? this.surahs,
      tasks: tasks ?? this.tasks,
      groupBy: groupBy ?? this.groupBy,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, reciters, activeReciterId, surahs, tasks, groupBy, totalBytes, error];
}
