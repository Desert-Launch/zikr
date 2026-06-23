import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_token.dart';

abstract class RTajweed {
  /// Tajweed tokens for every ayah appearing on [page], keyed by `"surah:ayah"`.
  /// Ayahs that span a page boundary appear (in full) on each page they touch,
  /// so the renderer can colour every word the QPC layout places on the page.
  Future<Either<Failure, Map<String, List<ETajweedToken>>>> getPage(int page);
}
