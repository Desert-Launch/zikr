import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/domain/entities/e_hizb_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
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
  Future<Either<Failure, MPageLayout>> getPage(
    int page, {
    EQuranFontMode mode = EQuranFontMode.plainV1,
  }) async {
    if (page < 1 || page > 604) {
      return Left(Failure.validationFailure(message: 'Page must be 1..604'));
    }
    try {
      return Right(await _local.loadPageForMode(page, mode));
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
      // Resolve surah names once so each hit can show a human-readable label.
      final surahs = await _local.loadSurahs();
      final byNumber = {for (final s in surahs) s.number: s};
      // Sort by (surah, ayah) ascending — matches the surface order users expect.
      final hits = raw
          .map((e) => QuranSearchHit(
                ref: e.ref,
                snippet: e.snippet,
                page: e.page,
                surahArabicName: byNumber[e.ref.surah]?.arabic ?? '',
                surahName: byNumber[e.ref.surah]?.name ?? '',
              ))
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

  /// Start of every hizb (1..60) as `[surah, ayah, page]` in the 604-page Madani
  /// mushaf. Derived from the Tanzil quarter/page metadata; the odd entries
  /// (hizb 2k-1) coincide with the start of juz' k, and the juz' start pages
  /// match `CBMushafReader`'s table. Two ahzab per juz', so juz' k owns rows
  /// `2k-2` and `2k-1` (0-based).
  static const List<List<int>> _hizbStarts = [
    [1, 1, 1], [2, 75, 11], [2, 142, 22], [2, 203, 32], [2, 253, 42],
    [3, 15, 51], [3, 93, 62], [3, 171, 72], [4, 24, 82], [4, 88, 92],
    [4, 148, 102], [5, 27, 112], [5, 82, 121], [6, 36, 132], [6, 111, 142],
    [7, 1, 151], [7, 88, 162], [7, 171, 173], [8, 41, 182], [9, 34, 192],
    [9, 93, 201], [10, 26, 212], [11, 6, 222], [11, 84, 231], [12, 53, 242],
    [13, 19, 252], [15, 1, 262], [16, 51, 272], [17, 1, 282], [17, 99, 292],
    [18, 75, 302], [20, 1, 312], [21, 1, 322], [22, 1, 332], [23, 1, 342],
    [24, 21, 352], [25, 21, 362], [26, 111, 371], [27, 56, 382], [28, 51, 392],
    [29, 46, 402], [31, 22, 413], [33, 31, 422], [34, 24, 431], [36, 28, 442],
    [37, 145, 451], [39, 32, 462], [40, 41, 472], [41, 47, 482], [43, 24, 491],
    [46, 1, 502], [48, 18, 513], [51, 31, 522], [55, 1, 531], [58, 1, 542],
    [62, 1, 553], [67, 1, 562], [72, 1, 572], [78, 1, 582], [87, 1, 591],
  ];

  @override
  Future<Either<Failure, List<EJuzEntry>>> getJuzIndex() async {
    try {
      final surahs = await _local.loadSurahs();
      final byNumber = {for (final s in surahs) s.number: s};
      String arabic(int surah) => byNumber[surah]?.arabic ?? '';

      EHizbEntry hizbAt(int row) {
        final r = _hizbStarts[row];
        return EHizbEntry(
          number: row + 1,
          startSurah: r[0],
          startAyah: r[1],
          startPage: r[2],
          startSurahArabic: arabic(r[0]),
        );
      }

      final out = <EJuzEntry>[];
      for (var juz = 1; juz <= 30; juz++) {
        final first = hizbAt((juz - 1) * 2);
        final second = hizbAt((juz - 1) * 2 + 1);
        out.add(EJuzEntry(
          number: juz,
          startSurah: first.startSurah,
          startAyah: first.startAyah,
          startPage: first.startPage,
          startSurahArabic: first.startSurahArabic,
          hizbs: [first, second],
        ));
      }
      return Right(out);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplQuran.getJuzIndex', error: e, stackTrace: st);
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
