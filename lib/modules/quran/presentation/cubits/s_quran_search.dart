import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_number_search.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SQuranSearch extends Equatable {
  const SQuranSearch({
    this.status = LoadStatus.idle,
    this.query = '',
    this.results = const [],
    this.numbers,
    this.error,
  });

  final LoadStatus status;
  final String query;
  final List<SearchHit> results;

  /// Set instead of [results] when the query is purely numeric — the page,
  /// surah and arba' that number names.
  final ENumberSearch? numbers;

  final String? error;

  /// Whether the current query is being answered as a number rather than text.
  bool get isNumeric => numbers != null;

  SQuranSearch copyWith({
    LoadStatus? status,
    String? query,
    List<SearchHit>? results,
    ENumberSearch? numbers,
    String? error,
    bool clearError = false,
    bool clearNumbers = false,
  }) {
    return SQuranSearch(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      numbers: clearNumbers ? null : (numbers ?? this.numbers),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, query, results, numbers, error];
}
