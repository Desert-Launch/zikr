import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class RImplQuran implements RQuran {
  RImplQuran(this._local);
  final DSLocalQuran _local;

  @override
  Future<Either<Failure, List<MSurah>>> getSurahs() async {
    try {
      return Right(await _local.loadSurahs());
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.getSurahs', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MSurah>> getSurah(int number) async {
    try {
      final list = await _local.loadSurahs();
      final s = list.firstWhere(
        (e) => e.number == number,
        orElse: () => throw StateError('Surah $number not found'),
      );
      return Right(s);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.getSurah', error: e, stackTrace: st);
      return Left(Failure.notFoundFailure(message: 'Surah $number not found'));
    }
  }

  @override
  Future<Either<Failure, MPageLayout>> getPage(int page) async {
    if (page < 1 || page > 604) {
      return Left(Failure.validationFailure(message: 'Page must be 1..604'));
    }
    try {
      return Right(await _local.loadPage(page));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.getPage', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> pageOfAyah(ParamAyahRef ref) async {
    try {
      return Right(await _local.pageOfAyah(ref.surah, ref.ayah));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.pageOfAyah', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfSurah(int surah) async {
    try {
      final list = await _local.loadSurahs();
      final s = list.firstWhere((e) => e.number == surah,
          orElse: () => throw StateError('Surah $surah not found'));
      return Right(List.generate(s.totalAyah, (i) => ParamAyahRef(surah: surah, ayah: i + 1)));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.ayatOfSurah', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  static const List<List<int>> _juzStarts = [
    [1, 1], [2, 142], [2, 253], [3, 93], [4, 24], [4, 148], [5, 82], [6, 111],
    [7, 88], [8, 41], [9, 93], [11, 6], [12, 53], [15, 1], [17, 1], [18, 75],
    [21, 1], [23, 1], [25, 21], [27, 56], [29, 46], [33, 31], [36, 28], [39, 32],
    [41, 47], [46, 1], [51, 31], [58, 1], [67, 1], [78, 1],
  ];

  @override
  Future<Either<Failure, List<QuranSearchHit>>> search(String query, {int limit = 200}) async {
    final q = query.trim();
    if (q.isEmpty) return const Right([]);
    try {
      final normalised = DSLocalQuran.normaliseForSearch(q);
      if (normalised.isEmpty) return const Right([]);
      final raw = await _local.searchNormalised(normalised, limit: limit);
      // Sort by (surah, ayah) ascending — matches the surface order users expect.
      final hits = raw
          .map((e) => QuranSearchHit(ref: e.ref, snippet: e.snippet))
          .toList()
        ..sort((a, b) {
          final s = a.ref.surah.compareTo(b.ref.surah);
          return s != 0 ? s : a.ref.ayah.compareTo(b.ref.ayah);
        });
      return Right(hits);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.search', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EDailyVerse>> getDailyVerse(
    DateTime day, {
    int maxChars = 85,
  }) async {
    try {
      final v = await _local.dailyVerse(day, maxChars: maxChars);
      return Right(EDailyVerse(
        surahNumber: v.surah.number,
        surahArabicName: v.surah.arabic,
        surahName: v.surah.name,
        ayah: v.ref.ayah,
        text: v.text,
      ));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.getDailyVerse', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfJuz(int juz) async {
    if (juz < 1 || juz > 30) {
      return Left(Failure.validationFailure(message: 'Juz must be 1..30'));
    }
    try {
      final surahs = await _local.loadSurahs();
      final from = _juzStarts[juz - 1];
      final to = juz < 30 ? _juzStarts[juz] : [114, surahs.last.totalAyah + 1];
      final out = <ParamAyahRef>[];
      for (final s in surahs) {
        for (int a = 1; a <= s.totalAyah; a++) {
          final beforeStart = s.number < from[0] || (s.number == from[0] && a < from[1]);
          final atOrAfterEnd = s.number > to[0] || (s.number == to[0] && a >= to[1]);
          if (!beforeStart && !atOrAfterEnd) {
            out.add(ParamAyahRef(surah: s.number, ayah: a));
          }
        }
      }
      return Right(out);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.ayatOfJuz', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
