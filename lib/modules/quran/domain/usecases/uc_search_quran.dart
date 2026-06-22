import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class SearchHit extends Equatable {
  const SearchHit({
    required this.ref,
    required this.snippet,
    required this.page,
    this.surahArabicName = '',
    this.surahName = '',
  });
  final ParamAyahRef ref;
  final String snippet;
  final int page;

  /// Arabic-script surah name, e.g. "البقرة".
  final String surahArabicName;

  /// Transliterated surah name, e.g. "Al-Baqarah".
  final String surahName;
  @override
  List<Object?> get props => [ref];
}

class UCSearchQuran {
  UCSearchQuran(this.repo);
  final RQuran repo;

  Future<Either<Failure, List<SearchHit>>> call(String query, {int limit = 200}) async {
    if (query.trim().length < 2) return const Right([]);
    final res = await repo.search(query, limit: limit);
    return res.map(
      (hits) => hits
          .map(
            (h) => SearchHit(
              ref: h.ref,
              snippet: h.snippet,
              page: h.page,
              surahArabicName: h.surahArabicName,
              surahName: h.surahName,
            ),
          )
          .toList(growable: false),
    );
  }
}
