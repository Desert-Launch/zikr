import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_page_entry.dart';

enum LoadStatus { idle, loading, success, error }

enum SurahFilter { all, makki, madani }

/// Which index the screen is browsing: the 114 surahs, the 30 ajzaa', or the
/// 604 pages.
enum QuranIndexMode { surah, juz, page }

class SSurahList extends Equatable {
  const SSurahList({
    this.status = LoadStatus.idle,
    this.all = const [],
    this.juzIndex = const [],
    this.pageIndex = const [],
    this.query = '',
    this.mode = QuranIndexMode.surah,
    this.filter = SurahFilter.all,
    this.juzFilter,
    this.lastRead,
    this.bookmarkCount = 0,
    this.error,
  });

  final LoadStatus status;
  final List<MSurah> all;
  final List<EJuzEntry> juzIndex;
  final List<EPageEntry> pageIndex;
  final String query;
  final QuranIndexMode mode;
  final SurahFilter filter;
  final int? juzFilter;
  final MLastRead? lastRead;
  final int bookmarkCount;
  final String? error;

  List<MSurah> get visible {
    var list = all;
    if (filter == SurahFilter.makki) list = list.where((s) => s.isMakki).toList();
    if (filter == SurahFilter.madani) list = list.where((s) => s.isMadani).toList();
    if (juzFilter != null) list = list.where((s) => s.juzStart == juzFilter).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((s) =>
        s.arabic.contains(query) ||
        s.name.toLowerCase().contains(q) ||
        s.translation.toLowerCase().contains(q) ||
        s.number.toString() == q
      ).toList();
    }
    return list;
  }

  SSurahList copyWith({
    LoadStatus? status,
    List<MSurah>? all,
    List<EJuzEntry>? juzIndex,
    List<EPageEntry>? pageIndex,
    String? query,
    QuranIndexMode? mode,
    SurahFilter? filter,
    int? juzFilter,
    bool clearJuzFilter = false,
    MLastRead? lastRead,
    bool clearLastRead = false,
    int? bookmarkCount,
    String? error,
    bool clearError = false,
  }) {
    return SSurahList(
      status: status ?? this.status,
      all: all ?? this.all,
      juzIndex: juzIndex ?? this.juzIndex,
      pageIndex: pageIndex ?? this.pageIndex,
      query: query ?? this.query,
      mode: mode ?? this.mode,
      filter: filter ?? this.filter,
      juzFilter: clearJuzFilter ? null : (juzFilter ?? this.juzFilter),
      lastRead: clearLastRead ? null : (lastRead ?? this.lastRead),
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, all, juzIndex, pageIndex, query, mode, filter, juzFilter, lastRead, bookmarkCount, error];
}
