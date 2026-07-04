import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Line kinds in the QPC-V4 page layout (`qpc_v4_ayah_info.json`).
enum QpcV4LineType {
  surahName,
  basmala,
  ayah;

  static QpcV4LineType fromJson(dynamic value) {
    switch ((value ?? '').toString()) {
      case 'surah_name':
        return QpcV4LineType.surahName;
      case 'basmallah':
        return QpcV4LineType.basmala;
      case 'ayah':
        return QpcV4LineType.ayah;
      default:
        throw FormatException('Unsupported QPC-V4 line_type: $value');
    }
  }
}

/// One word (glyph run) of a QPC-V4 ayah line, ready to render with the page's
/// colour font. [glyphs] is the PUA glyph string that only renders correctly
/// with the matching `qcf4_p{page}` font family.
class MQpcV4Segment extends Equatable {
  const MQpcV4Segment({
    required this.wordId,
    required this.ayahUq,
    required this.surah,
    required this.ayah,
    required this.wordNumber,
    required this.glyphs,
    required this.isAyahEnd,
  });

  final int wordId;

  /// Synthetic unique ayah id (`surah * 1000 + ayah`) — used to group the words
  /// of one ayah for tap selection.
  final int ayahUq;
  final int surah;
  final int ayah;
  final int wordNumber;
  final String glyphs;

  /// True on the last real word of an ayah — the caller appends the ayah-number
  /// rosette after it.
  final bool isAyahEnd;

  @override
  List<Object?> get props =>
      [wordId, ayahUq, surah, ayah, wordNumber, glyphs, isAyahEnd];
}

/// A renderable block on a QPC-V4 page: a surah header, a basmala, or an ayah
/// line. Mirrors the package's `QpcV4RenderBlock` hierarchy.
sealed class MQpcV4Block extends Equatable {
  const MQpcV4Block();
}

class MQpcV4SurahHeaderBlock extends MQpcV4Block {
  const MQpcV4SurahHeaderBlock(this.surahNumber);
  final int surahNumber;

  @override
  List<Object?> get props => [surahNumber];
}

class MQpcV4BasmalaBlock extends MQpcV4Block {
  const MQpcV4BasmalaBlock(this.surahNumber);
  final int surahNumber;

  @override
  List<Object?> get props => [surahNumber];
}

class MQpcV4LineBlock extends MQpcV4Block {
  const MQpcV4LineBlock({required this.isCentered, required this.segments});
  final bool isCentered;
  final List<MQpcV4Segment> segments;

  @override
  List<Object?> get props => [isCentered, segments];
}

/// A fully-resolved QPC-V4 page: an ordered list of render blocks.
class MQpcV4Page extends Equatable {
  const MQpcV4Page({required this.page, required this.blocks});
  final int page;
  final List<MQpcV4Block> blocks;

  /// Every distinct ayah on the page, in reading order — used by the reader for
  /// the running-head surah name and last-read tracking.
  List<ParamAyahRef> get allAyahRefs {
    final seen = <String>{};
    final refs = <ParamAyahRef>[];
    for (final block in blocks) {
      if (block is! MQpcV4LineBlock) continue;
      for (final seg in block.segments) {
        final ref = ParamAyahRef(surah: seg.surah, ayah: seg.ayah);
        if (seen.add(ref.key)) refs.add(ref);
      }
    }
    return refs;
  }

  @override
  List<Object?> get props => [page, blocks];
}
