import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';

class CBSurahList extends Cubit<SSurahList> {
  CBSurahList(this._getSurahs, this._lastRead, this._bookmarks) : super(const SSurahList());

  final UCGetSurahList _getSurahs;
  final UCSaveLastRead _lastRead;
  final UCGetBookmarks _bookmarks;

  Future<void> loadInitial() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final result = await _getSurahs();
    final lastReadRes = await _lastRead.getLastRead();
    final bookmarksRes = await _bookmarks();
    result.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (surahs) => emit(state.copyWith(
        status: LoadStatus.success,
        all: surahs,
        lastRead: lastReadRes.fold((_) => null, (r) => r),
        bookmarkCount: bookmarksRes.fold((_) => 0, (l) => l.length),
      )),
    );
  }

  void setFilter(SurahFilter filter) => emit(state.copyWith(filter: filter));
  void setQuery(String q) => emit(state.copyWith(query: q));
  void setJuzFilter(int? juz) =>
      juz == null ? emit(state.copyWith(clearJuzFilter: true)) : emit(state.copyWith(juzFilter: juz));
}
