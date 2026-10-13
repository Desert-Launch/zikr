import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SReciter extends Equatable {
  const SReciter({
    this.status = LoadStatus.idle,
    this.all = const <MReciter>[],
    this.activeId,
    this.previewingId,
    this.previewLoading = false,
    this.previewDuration,
    this.previewFailures = 0,
    this.error,
  });

  final LoadStatus status;
  final List<MReciter> all;
  final String? activeId;

  /// The reciter whose sample is loading or playing; `null` when idle.
  final String? previewingId;

  /// True while the sample for [previewingId] is still loading or buffering.
  final bool previewLoading;

  /// Length of the sample once it is ready to play — drives the tile's
  /// progress ring. `null` until known.
  final Duration? previewDuration;

  /// Bumped each time a sample fails to play, so the screen can tell the user
  /// once per failure (a one-shot signal, not a sticky error).
  final int previewFailures;

  final String? error;

  SReciter copyWith({
    LoadStatus? status,
    List<MReciter>? all,
    String? activeId,
    String? previewingId,
    bool? previewLoading,
    Duration? previewDuration,
    int? previewFailures,
    bool clearPreviewing = false,
    String? error,
  }) {
    return SReciter(
      status: status ?? this.status,
      all: all ?? this.all,
      activeId: activeId ?? this.activeId,
      previewingId: clearPreviewing ? null : (previewingId ?? this.previewingId),
      previewLoading: clearPreviewing ? false : (previewLoading ?? this.previewLoading),
      previewDuration: clearPreviewing ? null : (previewDuration ?? this.previewDuration),
      previewFailures: previewFailures ?? this.previewFailures,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, all, activeId, previewingId, previewLoading, previewDuration, previewFailures, error];
}
