import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// State for the tafsir library (browse / download / delete books).
class STafsirLibrary extends Equatable {
  const STafsirLibrary({
    this.status = LoadStatus.idle,
    this.books = const [],
    this.downloaded = const {},
    this.progress = const {},
    this.error,
  });

  final LoadStatus status;
  final List<ETafsirBook> books;

  /// Ids of books already stored on device.
  final Set<String> downloaded;

  /// bookId -> 0.0–1.0 while a download is in flight (absent when idle).
  final Map<String, double> progress;
  final String? error;

  bool isDownloaded(String id) => downloaded.contains(id);
  bool isDownloading(String id) => progress.containsKey(id);
  double progressFor(String id) => progress[id] ?? 0;

  STafsirLibrary copyWith({
    LoadStatus? status,
    List<ETafsirBook>? books,
    Set<String>? downloaded,
    Map<String, double>? progress,
    String? error,
    bool clearError = false,
  }) {
    return STafsirLibrary(
      status: status ?? this.status,
      books: books ?? this.books,
      downloaded: downloaded ?? this.downloaded,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, books, downloaded, progress, error];
}
