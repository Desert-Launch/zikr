import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_number_lookup.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus, normalizeArabicSearch;

class CBQuranSearch extends Cubit<SQuranSearch> {
  CBQuranSearch(this._search, this._numberLookup, this._getSurahs)
    : super(const SQuranSearch());

  final UCSearchQuran _search;
  final UCNumberLookup _numberLookup;
  final UCGetSurahList _getSurahs;
  Timer? _debounce;
  int _seq = 0;

  /// Shortest query the verse-text search runs for. Below it only surah names
  /// are matched: one letter matches a large share of the 6236 ayat, which is
  /// slow to gather and useless to read.
  static const int _minTextChars = 2;

  /// The 114 surahs, loaded once and kept — every keystroke filters them.
  List<MSurah> _surahIndex = const [];

  /// Updates the query and runs a debounced search. A query made only of digits
  /// — Arabic-Indic or Latin — is answered as a number (page / surah / hizb)
  /// instead of being looked for in the text, so a single digit is enough.
  ///
  /// A single letter searches surah names only; from two letters on the verse
  /// text is searched too and both sets of results are returned.
  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    final trimmed = query.trim();

    final number = _asNumber(trimmed);
    if (number != null) {
      _debounce = Timer(const Duration(milliseconds: 250), () => _runNumber(number));
      return;
    }

    if (trimmed.isEmpty) {
      emit(state.copyWith(
        status: LoadStatus.idle,
        results: const [],
        surahs: const [],
        clearNumbers: true,
      ));
      return;
    }

    if (trimmed.length < _minTextChars) {
      _debounce = Timer(
        const Duration(milliseconds: 150),
        () => _runSurahsOnly(trimmed),
      );
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(trimmed));
  }

  /// Answers a one-letter query from the surah index alone.
  Future<void> _runSurahsOnly(String query) async {
    final mySeq = ++_seq;
    final surahs = _matchSurahs(await _surahs(), query);
    if (mySeq != _seq) return; // stale — newer query in flight.
    emit(state.copyWith(
      status: LoadStatus.success,
      results: const [],
      surahs: surahs,
      clearNumbers: true,
    ));
  }

  Future<void> _run(String query) async {
    final mySeq = ++_seq;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true, clearNumbers: true));
    final surahs = _matchSurahs(await _surahs(), query);
    final res = await _search(query);
    if (mySeq != _seq) return; // stale — newer query in flight.
    res.fold(
      (f) => emit(state.copyWith(
        status: LoadStatus.error,
        error: f.message,
        surahs: surahs,
      )),
      (hits) => emit(state.copyWith(
        status: LoadStatus.success,
        results: hits,
        surahs: surahs,
      )),
    );
  }

  /// The surah index, loaded on the first query and kept for the rest.
  Future<List<MSurah>> _surahs() async {
    if (_surahIndex.isNotEmpty) return _surahIndex;
    final res = await _getSurahs();
    return _surahIndex = res.fold((_) => const <MSurah>[], (list) => list);
  }

  /// Surahs whose Arabic name (short or long), transliteration or translation
  /// contains [query]. Arabic is folded first, so "الاعراف" matches "الأعراف".
  static List<MSurah> _matchSurahs(List<MSurah> all, String query) {
    final lower = query.toLowerCase();
    // Folding can empty the query (it was all tashkeel); an empty needle would
    // otherwise match every surah.
    final arabic = normalizeArabicSearch(query);
    if (lower.isEmpty) return const [];
    return all
        .where(
          (s) =>
              (arabic.isNotEmpty &&
                  (normalizeArabicSearch(s.arabic).contains(arabic) ||
                      normalizeArabicSearch(s.arabicLong).contains(arabic))) ||
              s.name.toLowerCase().contains(lower) ||
              s.translation.toLowerCase().contains(lower),
        )
        .toList(growable: false);
  }

  Future<void> _runNumber(int number) async {
    final mySeq = ++_seq;
    emit(state.copyWith(
      status: LoadStatus.loading,
      clearError: true,
      results: const [],
      surahs: const [],
    ));
    final res = await _numberLookup(number);
    if (mySeq != _seq) return; // stale — newer query in flight.
    res.fold(
      (f) => emit(state.copyWith(status: LoadStatus.error, error: f.message, clearNumbers: true)),
      (found) => emit(state.copyWith(status: LoadStatus.success, numbers: found)),
    );
  }

  void clear() {
    _debounce?.cancel();
    emit(const SQuranSearch());
  }

  /// Reads [query] as a mushaf number, or null when it isn't one. Accepts Latin
  /// and Arabic-Indic digits (both the Arabic and the extended Persian block),
  /// and rejects anything longer than four digits so a stray run of numerals
  /// still falls through to the text search.
  static int? _asNumber(String query) {
    if (query.isEmpty || query.length > 4) return null;
    final buffer = StringBuffer();
    for (final code in query.codeUnits) {
      if (code >= 0x0030 && code <= 0x0039) {
        buffer.writeCharCode(code); // 0-9
      } else if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(code - 0x0660 + 0x0030); // ٠-٩
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(code - 0x06F0 + 0x0030); // ۰-۹
      } else {
        return null;
      }
    }
    final value = int.tryParse(buffer.toString());
    return (value == null || value < 1) ? null : value;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
