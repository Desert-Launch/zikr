import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_number_lookup.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class CBQuranSearch extends Cubit<SQuranSearch> {
  CBQuranSearch(this._search, this._numberLookup) : super(const SQuranSearch());

  final UCSearchQuran _search;
  final UCNumberLookup _numberLookup;
  Timer? _debounce;
  int _seq = 0;

  /// Updates the query and runs a debounced search. A query made only of digits
  /// — Arabic-Indic or Latin — is answered as a number (page / surah / hizb)
  /// instead of being looked for in the text, so a single digit is enough.
  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    final trimmed = query.trim();

    final number = _asNumber(trimmed);
    if (number != null) {
      _debounce = Timer(const Duration(milliseconds: 250), () => _runNumber(number));
      return;
    }

    if (trimmed.length < 2) {
      emit(state.copyWith(status: LoadStatus.idle, results: const [], clearNumbers: true));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    final mySeq = ++_seq;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true, clearNumbers: true));
    final res = await _search(query);
    if (mySeq != _seq) return; // stale — newer query in flight.
    res.fold(
      (f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)),
      (hits) => emit(state.copyWith(status: LoadStatus.success, results: hits)),
    );
  }

  Future<void> _runNumber(int number) async {
    final mySeq = ++_seq;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true, results: const []));
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
