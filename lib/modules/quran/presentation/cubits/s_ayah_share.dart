import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_share.dart';
import 'package:quran/modules/quran/domain/entities/e_share_format.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

/// Which end of the range the wheel is currently moving.
enum EShareRangeEdge { from, to }

/// State of the share sheet: what the reader has chosen, and the resolved
/// content those choices produce.
class SAyahShare extends Equatable {
  const SAyahShare({
    this.status = LoadStatus.idle,
    this.surah = 1,
    this.from = 1,
    this.to = 1,
    this.ayahCount = 7,
    this.format = EShareFormat.image,
    this.bookIds = const [],
    this.availableBooks = const [],
    this.appBadge = true,
    this.edge,
    this.downloads = const {},
    this.content,
    this.error,
  });

  final LoadStatus status;

  final int surah;

  /// First and last verse of the range. [from] is the ayah the reader opened
  /// the sheet on and never moves past [to].
  final int from;
  final int to;

  /// How many verses the surah has — the bounds of the range wheels.
  final int ayahCount;

  final EShareFormat format;

  /// Attached books, in the order they will be printed.
  final List<String> bookIds;

  /// Books that can be attached: the ones already downloaded. A book has to be
  /// on the device to be shared, so the library is the way to add more.
  final List<ETafsirBook> availableBooks;

  final bool appBadge;

  /// Which of the two range rows the wheel below them is editing, or null
  /// while the wheel is put away — which is how the sheet opens. Most shares
  /// are one verse, and a wheel is only worth the room it takes once the
  /// reader has said they want to change the range.
  final EShareRangeEdge? edge;

  /// Download progress, 0..1, for catalogue books being fetched from the book
  /// picker. A book is in this map only while its download is in flight.
  final Map<String, double> downloads;

  /// The resolved verses and commentary. Null until the first resolve lands.
  final EAyahShare? content;

  final String? error;

  int get count => (to - from).abs() + 1;

  /// Books that are downloaded but not attached yet — what the "add a book"
  /// picker offers.
  List<ETafsirBook> get addableBooks =>
      availableBooks.where((b) => !bookIds.contains(b.id)).toList();

  bool get isImage => format == EShareFormat.image;

  /// Lowest verse the wheel offers for the edge it is on. The end of a range
  /// cannot come before its start, so the `to` wheel begins at [from] rather
  /// than showing verses that could never be picked.
  int get wheelFirst => edge == EShareRangeEdge.to ? from : 1;

  /// The verse the wheel is currently parked on.
  int get wheelValue => edge == EShareRangeEdge.from ? from : to;

  bool isDownloading(String bookId) => downloads.containsKey(bookId);
  double progressFor(String bookId) => downloads[bookId] ?? 0;
  bool isDownloaded(String bookId) =>
      availableBooks.any((b) => b.id == bookId);

  SAyahShare copyWith({
    LoadStatus? status,
    int? surah,
    int? from,
    int? to,
    int? ayahCount,
    EShareFormat? format,
    List<String>? bookIds,
    List<ETafsirBook>? availableBooks,
    bool? appBadge,
    EShareRangeEdge? edge,
    bool clearEdge = false,
    Map<String, double>? downloads,
    EAyahShare? content,
    String? error,
    bool clearError = false,
  }) => SAyahShare(
    status: status ?? this.status,
    surah: surah ?? this.surah,
    from: from ?? this.from,
    to: to ?? this.to,
    ayahCount: ayahCount ?? this.ayahCount,
    format: format ?? this.format,
    bookIds: bookIds ?? this.bookIds,
    availableBooks: availableBooks ?? this.availableBooks,
    appBadge: appBadge ?? this.appBadge,
    edge: clearEdge ? null : (edge ?? this.edge),
    downloads: downloads ?? this.downloads,
    content: content ?? this.content,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    status,
    surah,
    from,
    to,
    ayahCount,
    format,
    bookIds,
    availableBooks,
    appBadge,
    edge,
    downloads,
    content,
    error,
  ];
}
