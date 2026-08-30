import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_text.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_number_search.dart';
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

  /// Plain Uthmani text for the run of verses [from]..[to] in [surah], in
  /// order. Used wherever verses leave the app — the reader's own page is drawn
  /// from glyph fonts nobody else can read.
  Future<Either<Failure, List<EAyahText>>> ayahRangeText(
    int surah,
    int from,
    int to,
  );

  /// Returns all ayah refs in [surah] in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfSurah(int surah);

  /// Returns all ayah refs of [juz] (1..30) in document order.
  Future<Either<Failure, List<ParamAyahRef>>> ayatOfJuz(int juz);

  /// Returns the 30 ajzaa' with the page where each one begins.
  Future<Either<Failure, List<EJuzEntry>>> getJuzIndex();

  /// Deterministic "verse of the day" for the given calendar [day], constrained
  /// to verses longer than [minChars] and no longer than [maxChars] so it fits
  /// the home card and isn't trivially short. A non-zero [seed] returns a
  /// different verse for the same day (manual refresh).
  Future<Either<Failure, EDailyVerse>> getDailyVerse(
    DateTime day, {
    int maxChars,
    int minChars,
    int seed,
  });

  /// Diacritics-tolerant Uthmani text search across all 6236 ayat.
  /// Returns hits in canonical order (surah, ayah), capped at [limit].
  Future<Either<Failure, List<QuranSearchHit>>> search(String query, {int limit});

  /// Resolves a purely numeric query into the page, surah and hizb it names.
  Future<Either<Failure, ENumberSearch>> numberLookup(int number);
}
