import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_data.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/e_share_glyph_run.dart';
import 'package:quran/modules/quran/domain/repos/r_quran_v4.dart';

class RImplQuranV4 implements RQuranV4 {
  RImplQuranV4(this._data, this._fonts);
  final DSQpcV4Data _data;
  final DSQpcV4FontLoader _fonts;

  /// The variant a shared card is printed in: plain black on the card's cream,
  /// the way the Mushaf itself is printed. The card keeps a fixed light palette
  /// whatever the reader's own theme is, so this pair is fixed too.
  static const bool _cardDark = false;
  static const bool _cardTajweed = false;

  @override
  Future<Either<Failure, MQpcV4Page>> getPage(int page) async {
    if (page < 1 || page > 604) {
      return Left(Failure.validationFailure(message: 'Page must be 1..604'));
    }
    try {
      return Right(await _data.loadPage(page));
    } catch (e, st) {
      ErrorHelper.printDebugError(
          name: 'RImplQuranV4.getPage', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EShareGlyphRun>>> glyphRunsForRange({
    required int surah,
    required int from,
    required int to,
    required int startPage,
  }) async {
    try {
      final segments = await _data.segmentsForRange(
        surah: surah,
        from: from,
        to: to,
        startPage: startPage,
      );
      // Register every page the passage touches before handing the runs over.
      // A glyph drawn in an unregistered family is a row of empty boxes, and
      // the card is captured to a file — there is no second frame to fix it in.
      final pages = {for (final run in segments) run.page};
      for (final page in pages) {
        await _fonts.loadPage(page, dark: _cardDark, tajweed: _cardTajweed);
      }
      return Right([
        for (final run in segments)
          EShareGlyphRun(
            fontFamily: _fonts.familyFor(
              run.page,
              dark: _cardDark,
              tajweed: _cardTajweed,
            ),
            glyphs: run.segment.glyphs,
            ayah: run.segment.ayah,
            isAyahEnd: run.segment.isAyahEnd,
          ),
      ]);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplQuranV4.glyphRunsForRange',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
