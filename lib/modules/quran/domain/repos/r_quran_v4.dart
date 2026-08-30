import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/e_share_glyph_run.dart';

/// Reader repository for the QPC-V4 colored-tajweed Mushaf edition.
abstract class RQuranV4 {
  /// Resolves [page] (1..604) into renderable QPC-V4 blocks.
  Future<Either<Failure, MQpcV4Page>> getPage(int page);

  /// The printed glyphs for verses [from]..[to] of [surah], with the page fonts
  /// they need already registered — so what comes back can be drawn straight
  /// away rather than after a frame of empty boxes.
  ///
  /// [startPage] is where the walk begins; the range's own first page.
  Future<Either<Failure, List<EShareGlyphRun>>> glyphRunsForRange({
    required int surah,
    required int from,
    required int to,
    required int startPage,
  });
}
