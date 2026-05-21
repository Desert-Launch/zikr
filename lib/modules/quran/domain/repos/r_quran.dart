import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

abstract class RQuran {
  Future<Either<Failure, List<MSurah>>> getSurahs();
  Future<Either<Failure, MSurah>> getSurah(int number);
  Future<Either<Failure, MPageLayout>> getPage(int page);

  /// Returns the page number where the given ayah lives.
  Future<Either<Failure, int>> pageOfAyah(ParamAyahRef ref);

  /// Returns all ayah refs in [surah] in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfSurah(int surah);

  /// Returns all ayah refs of [juz] (1..30) in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfJuz(int juz);
}
