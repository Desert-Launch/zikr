import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SReciterDownloads extends Equatable {
  const SReciterDownloads({
    this.status = LoadStatus.idle,
    this.reciters = const <MReciter>[],
    this.stats = const <String, ReciterStats>{},
    this.error,
  });

  final LoadStatus status;
  final List<MReciter> reciters;

  /// Per-reciter disk stats, keyed by reciter id. Populated lazily after the
  /// reciter list loads, so the list renders immediately.
  final Map<String, ReciterStats> stats;
  final String? error;

  SReciterDownloads copyWith({
    LoadStatus? status,
    List<MReciter>? reciters,
    Map<String, ReciterStats>? stats,
    String? error,
    bool clearError = false,
  }) {
    return SReciterDownloads(
      status: status ?? this.status,
      reciters: reciters ?? this.reciters,
      stats: stats ?? this.stats,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, reciters, stats, error];
}
