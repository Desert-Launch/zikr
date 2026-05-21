import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SBookmarks extends Equatable {
  const SBookmarks({this.status = LoadStatus.idle, this.all = const [], this.error});

  final LoadStatus status;
  final List<MBookmark> all;
  final String? error;

  SBookmarks copyWith({LoadStatus? status, List<MBookmark>? all, String? error}) {
    return SBookmarks(
      status: status ?? this.status,
      all: all ?? this.all,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, all, error];
}
