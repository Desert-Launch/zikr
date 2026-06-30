import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_page_entry.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_juz_index.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';

class CBSurahList extends Cubit<SSurahList> {
  CBSurahList(this._getSurahs, this._lastRead, this._bookmarks, this._getJuzIndex) : super(const SSurahList());

  final UCGetSurahList _getSurahs;
  final UCSaveLastRead _lastRead;
  final UCGetBookmarks _bookmarks;
  final UCGetJuzIndex _getJuzIndex;

  StreamSubscription<List<dynamic>>? _bookmarksSub;

  Future<void> loadInitial() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final result = await _getSurahs();
    final lastReadRes = await _lastRead.getLastRead();
    final bookmarksRes = await _bookmarks();
    final juzRes = await _getJuzIndex();
    result.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (surahs) => emit(state.copyWith(
        status: LoadStatus.success,
        all: surahs,
        juzIndex: juzRes.fold((_) => const [], (l) => l),
        pageIndex: _buildPageIndex(surahs),
        lastRead: lastReadRes.fold((_) => null, (r) => r),
        bookmarkCount: bookmarksRes.fold((_) => 0, (l) => l.length),
      )),
    );
    // Keep the bookmark count live so the summary card updates instantly when a
    // bookmark is added/removed elsewhere (e.g. from the mushaf reader).
    _bookmarksSub ??= _bookmarks.watch().listen((list) {
      if (!isClosed) emit(state.copyWith(bookmarkCount: list.length));
    });
  }

  /// Maps every mushaf page (1..604) to the surah it falls in — the surah with
  /// the greatest `pageStart` that is `<= page`.
  List<EPageEntry> _buildPageIndex(List<MSurah> surahs) {
    if (surahs.isEmpty) return const [];
    final sorted = [...surahs]..sort((a, b) => a.pageStart.compareTo(b.pageStart));
    final out = <EPageEntry>[];
    var idx = 0;
    for (var page = 1; page <= 604; page++) {
      while (idx + 1 < sorted.length && sorted[idx + 1].pageStart <= page) {
        idx++;
      }
      final surah = sorted[idx];
      out.add(EPageEntry(page: page, surahNumber: surah.number, surahArabic: surah.arabic));
    }
    return out;
  }

  @override
  Future<void> close() async {
    await _bookmarksSub?.cancel();
    return super.close();
  }

  void setMode(QuranIndexMode mode) => emit(state.copyWith(mode: mode));
  void setFilter(SurahFilter filter) => emit(state.copyWith(filter: filter));
  void setQuery(String q) => emit(state.copyWith(query: q));
  void setJuzFilter(int? juz) =>
      juz == null ? emit(state.copyWith(clearJuzFilter: true)) : emit(state.copyWith(juzFilter: juz));
}
