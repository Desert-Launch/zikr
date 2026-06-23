import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_tajweed.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_token.dart';
import 'package:quran/modules/quran/domain/repos/r_tajweed.dart';

class RImplTajweed implements RTajweed {
  RImplTajweed(this._local);
  final DSLocalTajweed _local;

  @override
  Future<Either<Failure, Map<String, List<ETajweedToken>>>> getPage(
    int page,
  ) async {
    if (page < 1 || page > 604) {
      return Left(Failure.validationFailure(message: 'Page must be 1..604'));
    }
    try {
      final raw = await _local.loadPage(page);
      final out = <String, List<ETajweedToken>>{
        for (final entry in raw.entries)
          entry.key: entry.value.map((t) => t.toEntity()).toList(growable: false),
      };
      return Right(out);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplTajweed.getPage',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
