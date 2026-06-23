import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_token.dart';
import 'package:quran/modules/quran/domain/repos/r_tajweed.dart';

class UCGetTajweedTokens {
  UCGetTajweedTokens(this._repo);
  final RTajweed _repo;

  /// Tajweed tokens for every ayah on [page], keyed by `"surah:ayah"`.
  Future<Either<Failure, Map<String, List<ETajweedToken>>>> call(int page) =>
      _repo.getPage(page);
}
