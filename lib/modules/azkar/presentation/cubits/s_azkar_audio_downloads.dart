import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';

enum AzkarDownloadsStatus { idle, loading, ready, error }

/// State of the adhkar audio download manager.
class SAzkarAudioDownloads extends Equatable {
  const SAzkarAudioDownloads({
    this.status = AzkarDownloadsStatus.idle,
    this.readers = const <MAzkarReader>[],
    this.stats = const <String, AzkarReaderStats>{},
    this.progress = const <String, AzkarPackProgress>{},
    this.categories = const <String, List<AzkarCategoryAudioInfo>>{},
    this.storage = const AzkarStorageUsage.empty(),
    this.preferredReaderId,
    this.error,
  });

  final AzkarDownloadsStatus status;
  final List<MAzkarReader> readers;

  /// Per-reader disk figures, keyed by reader id. Filled in after the list
  /// renders so the screen appears immediately.
  final Map<String, AzkarReaderStats> stats;

  /// Live progress of in-flight runs, keyed by reader id.
  final Map<String, AzkarPackProgress> progress;

  /// Per-reader category breakdown, loaded when a reader's detail is opened.
  final Map<String, List<AzkarCategoryAudioInfo>> categories;

  final AzkarStorageUsage storage;
  final String? preferredReaderId;
  final String? error;

  bool isDownloading(String readerId) {
    final p = progress[readerId];
    return p != null && !p.isDone;
  }

  AzkarReaderStats statsFor(String readerId) =>
      stats[readerId] ?? AzkarReaderStats.empty(readerId);

  List<AzkarCategoryAudioInfo> categoriesFor(String readerId) =>
      categories[readerId] ?? const <AzkarCategoryAudioInfo>[];

  MAzkarReader? readerById(String readerId) {
    for (final r in readers) {
      if (r.id == readerId) return r;
    }
    return null;
  }

  SAzkarAudioDownloads copyWith({
    AzkarDownloadsStatus? status,
    List<MAzkarReader>? readers,
    Map<String, AzkarReaderStats>? stats,
    Map<String, AzkarPackProgress>? progress,
    Map<String, List<AzkarCategoryAudioInfo>>? categories,
    AzkarStorageUsage? storage,
    String? preferredReaderId,
    String? error,
    bool clearError = false,
    bool clearPreferred = false,
  }) {
    return SAzkarAudioDownloads(
      status: status ?? this.status,
      readers: readers ?? this.readers,
      stats: stats ?? this.stats,
      progress: progress ?? this.progress,
      categories: categories ?? this.categories,
      storage: storage ?? this.storage,
      preferredReaderId: clearPreferred
          ? null
          : (preferredReaderId ?? this.preferredReaderId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    readers,
    stats,
    progress,
    categories,
    storage,
    preferredReaderId,
    error,
  ];
}
