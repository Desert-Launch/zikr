import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_share.dart';
import 'package:quran/modules/quran/domain/entities/e_share_glyph_run.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/entities/param_share_range.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/repos/r_quran_v4.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

/// Resolves a share request into everything both outputs need: the surah, the
/// verses' Uthmani text, and each attached book's commentary flattened to
/// paragraphs.
///
/// A missing or unreadable book is dropped rather than failing the share — the
/// verses are the point, and a reader who asked for three books and gets two
/// is better served than one who gets an error.
class UCBuildAyahShare {
  UCBuildAyahShare(this._quran, this._tafsir, this._v4);

  final RQuran _quran;
  final RTafsir _tafsir;
  final RQuranV4 _v4;

  Future<Either<Failure, EAyahShare>> call(ParamShareRange params) async {
    final surah = await _quran.getSurah(params.surah);
    final failedSurah = surah.fold<Failure?>((f) => f, (_) => null);
    if (failedSurah != null) return Left(failedSurah);

    final ayat = await _quran.ayahRangeText(
      params.surah,
      params.from,
      params.to,
    );
    final failedAyat = ayat.fold<Failure?>((f) => f, (_) => null);
    if (failedAyat != null) return Left(failedAyat);

    return Right(
      EAyahShare(
        surah: surah.getOrElse(() => throw StateError('checked above')),
        ayat: ayat.getOrElse(() => const []),
        tafsir: await _collectTafsir(params),
        glyphs: await _collectGlyphs(params),
      ),
    );
  }

  /// The passage as printed glyphs, or empty when they cannot be had.
  ///
  /// A failure here is not a failure of the share: the card falls back to a
  /// text face, which is worse-looking but still correct, and the text formats
  /// are unaffected either way.
  Future<List<EShareGlyphRun>> _collectGlyphs(ParamShareRange params) async {
    final first = params.from <= params.to ? params.from : params.to;
    final last = params.from <= params.to ? params.to : params.from;
    final page = await _quran.pageOfAyah(
      ParamAyahRef(surah: params.surah, ayah: first),
    );
    final startPage = page.getOrElse(() => 0);
    if (startPage < 1) return const [];
    final runs = await _v4.glyphRunsForRange(
      surah: params.surah,
      from: first,
      to: last,
      startPage: startPage,
    );
    return runs.getOrElse(() => const []);
  }

  /// One [EShareTafsir] per requested book, in the reader's order, skipping
  /// books that turn out to have nothing to say about this range.
  Future<List<EShareTafsir>> _collectTafsir(ParamShareRange params) async {
    if (params.bookIds.isEmpty) return const [];
    final first = params.from <= params.to ? params.from : params.to;
    final last = params.from <= params.to ? params.to : params.from;

    // One pass over the range collects every book at once, so a three-book
    // share of ten verses reads each verse's commentary once rather than three
    // times over.
    final paragraphs = <String, List<String>>{
      for (final id in params.bookIds) id: <String>[],
    };
    // Guards against a book that answers a group of verses with one passage
    // repeating that passage under every verse of the group.
    final seen = <String, Set<String>>{
      for (final id in params.bookIds) id: <String>{},
    };

    for (var ayah = first; ayah <= last; ayah++) {
      final result = await _tafsir.getForAyah(
        ParamAyahRef(surah: params.surah, ayah: ayah),
      );
      final entries = result.getOrElse(() => const []);
      for (final entry in entries) {
        final bucket = paragraphs[entry.book.id];
        if (bucket == null) continue;
        final text = tafsirHtmlToPlainText(entry.html);
        if (text.isEmpty) continue;
        // A linked entry names the verse its text really belongs to; two verses
        // pointing at the same source are the same passage.
        if (!(seen[entry.book.id]?.add(entry.linkedFromKey ?? text) ?? false)) {
          continue;
        }
        bucket.add(text);
      }
    }

    return [
      for (final id in params.bookIds)
        if ((paragraphs[id] ?? const []).isNotEmpty)
          EShareTafsir(
            book: TafsirCatalog.byIdOrPlaceholder(id),
            paragraphs: paragraphs[id] ?? const [],
          ),
    ];
  }
}

/// Flattens a QUL commentary's HTML into the plain paragraphs a share carries.
///
/// The books' markup is simple — paragraphs, line breaks, the odd heading and
/// emphasis — so this trades a parser for a handful of substitutions and keeps
/// the share layer free of a rendering dependency.
String tafsirHtmlToPlainText(String html) {
  var text = html
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*(p|div|h[1-6]|li)\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  const entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
  entities.forEach((from, to) => text = text.replaceAll(from, to));
  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}
