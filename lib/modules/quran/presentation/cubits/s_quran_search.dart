import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_number_search.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SQuranSearch extends Equatable {
  const SQuranSearch({
    this.status = LoadStatus.idle,
    this.query = '',
    this.results = const [],
    this.surahs = const [],
    this.numbers,
    this.error,
  });

  final LoadStatus status;
  final String query;
  final List<SearchHit> results;

  /// Surahs whose name matches the query. Answered from the 114-entry index, so
  /// they are there from the very first letter — the verse text search needs
  /// two before it runs.
  final List<MSurah> surahs;

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
    List<MSurah>? surahs,
    ENumberSearch? numbers,
    String? error,
    bool clearError = false,
    bool clearNumbers = false,
  }) {
    return SQuranSearch(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      surahs: surahs ?? this.surahs,
      numbers: clearNumbers ? null : (numbers ?? this.numbers),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, query, results, surahs, numbers, error];
}
