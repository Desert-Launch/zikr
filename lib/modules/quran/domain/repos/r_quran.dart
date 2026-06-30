import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

class QuranSearchHit {
  const QuranSearchHit({
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
}

abstract class RQuran {
  Future<Either<Failure, List<MSurah>>> getSurahs();
  Future<Either<Failure, MSurah>> getSurah(int number);
  Future<Either<Failure, MPageLayout>> getPage(
    int page, {
    EQuranFontMode mode,
  });

  /// Returns the page number where the given ayah lives.
  Future<Either<Failure, int>> pageOfAyah(ParamAyahRef ref);

  /// Returns all ayah refs in [surah] in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfSurah(int surah);

  /// Returns all ayah refs of [juz] (1..30) in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfJuz(int juz);

  /// Returns the 30 ajzaa' with the page where each one begins.
  Future<Either<Failure, List<EJuzEntry>>> getJuzIndex();

  /// Deterministic "verse of the day" for the given calendar [day], constrained
  /// to verses no longer than [maxChars] so it fits the home card.
  Future<Either<Failure, EDailyVerse>> getDailyVerse(
    DateTime day, {
    int maxChars,
  });

  /// Diacritics-tolerant Uthmani text search across all 6236 ayat.
  /// Returns hits in canonical order (surah, ayah), capped at [limit].
  Future<Either<Failure, List<QuranSearchHit>>> search(String query, {int limit});
}
