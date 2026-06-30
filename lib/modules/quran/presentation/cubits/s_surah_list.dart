import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_page_entry.dart';

enum LoadStatus { idle, loading, success, error }

/// Folds Arabic orthographic variants so search is forgiving of how the user
/// types: drops tashkeel (harakat) and tatweel, and unifies the alef, ya, and
/// ta-marbuta forms (e.g. أ/إ/آ/ٱ → ا, ة → ه, ى → ي). Latin text is only
/// lower-cased. Lets "الاعراف", "الأعراف" and "اعراف" all match "الأعراف".
String normalizeArabicSearch(String input) {
  final buf = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    switch (rune) {
      // Harakat / superscript alef / tatweel → dropped.
      case 0x064B || 0x064C || 0x064D || 0x064E || 0x064F || 0x0650:
      case 0x0651 || 0x0652 || 0x0653 || 0x0654 || 0x0655 || 0x0670:
      case 0x0640:
        continue;
      // Alef variants → bare alef.
      case 0x0622 || 0x0623 || 0x0625 || 0x0671:
        buf.writeCharCode(0x0627);
      // Ta-marbuta → ha.
      case 0x0629:
        buf.writeCharCode(0x0647);
      // Alef-maqsura → ya.
      case 0x0649:
        buf.writeCharCode(0x064A);
      default:
        buf.writeCharCode(rune);
    }
  }
  return buf.toString().trim();
}

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
    if (filter == SurahFilter.makki) {
      list = list.where((s) => s.isMakki).toList();
    }
    if (filter == SurahFilter.madani) {
      list = list.where((s) => s.isMadani).toList();
    }
    if (juzFilter != null) {
      list = list.where((s) => s.juzStart == juzFilter).toList();
    }
    final q = query.trim();
    if (q.isNotEmpty) {
      final qLower = q.toLowerCase();
      final qAr = normalizeArabicSearch(q);
      list = list
          .where(
            (s) =>
                normalizeArabicSearch(s.arabic).contains(qAr) ||
                normalizeArabicSearch(s.arabicLong).contains(qAr) ||
                s.name.toLowerCase().contains(qLower) ||
                s.translation.toLowerCase().contains(qLower) ||
                s.number.toString() == qLower,
          )
          .toList();
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
  List<Object?> get props => [
    status,
    all,
    juzIndex,
    pageIndex,
    query,
    mode,
    filter,
    juzFilter,
    lastRead,
    bookmarkCount,
    error,
  ];
}
