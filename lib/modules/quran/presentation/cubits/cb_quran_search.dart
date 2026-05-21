import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class CBQuranSearch extends Cubit<SQuranSearch> {
  CBQuranSearch(this._search) : super(const SQuranSearch());

  final UCSearchQuran _search;
  Timer? _debounce;
  int _seq = 0;

  /// Updates the query and runs a debounced search.
  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      emit(state.copyWith(status: LoadStatus.idle, results: const []));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    final mySeq = ++_seq;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final res = await _search(query);
    if (mySeq != _seq) return; // stale — newer query in flight.
    res.fold(
      (f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)),
      (hits) => emit(state.copyWith(status: LoadStatus.success, results: hits)),
    );
  }

  void clear() {
    _debounce?.cancel();
    emit(const SQuranSearch());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
