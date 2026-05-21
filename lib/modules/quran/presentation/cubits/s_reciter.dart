import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SReciter extends Equatable {
  const SReciter({
    this.status = LoadStatus.idle,
    this.all = const <MReciter>[],
    this.activeId,
    this.previewingId,
    this.error,
  });

  final LoadStatus status;
  final List<MReciter> all;
  final String? activeId;
  final String? previewingId;
  final String? error;

  SReciter copyWith({
    LoadStatus? status,
    List<MReciter>? all,
    String? activeId,
    String? previewingId,
    bool clearPreviewing = false,
    String? error,
  }) {
    return SReciter(
      status: status ?? this.status,
      all: all ?? this.all,
      activeId: activeId ?? this.activeId,
      previewingId: clearPreviewing ? null : (previewingId ?? this.previewingId),
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, all, activeId, previewingId, error];
}
