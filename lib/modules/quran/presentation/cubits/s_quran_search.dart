import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SQuranSearch extends Equatable {
  const SQuranSearch({
    this.status = LoadStatus.idle,
    this.query = '',
    this.results = const [],
    this.error,
  });

  final LoadStatus status;
  final String query;
  final List<SearchHit> results;
  final String? error;

  SQuranSearch copyWith({
    LoadStatus? status,
    String? query,
    List<SearchHit>? results,
    String? error,
    bool clearError = false,
  }) {
    return SQuranSearch(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, query, results, error];
}
