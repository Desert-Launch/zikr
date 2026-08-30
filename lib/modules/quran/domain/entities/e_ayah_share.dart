import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_text.dart';
import 'package:quran/modules/quran/domain/entities/e_share_glyph_run.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';

/// One book's commentary on the shared range, already flattened out of the
/// book's HTML into paragraphs.
///
/// A book usually has one paragraph per ayah, but not always: several books
/// write one passage for a group of verses, in which case the group is carried
/// once rather than repeated under every ayah it covers.
class EShareTafsir extends Equatable {
  const EShareTafsir({required this.book, required this.paragraphs});

  final ETafsirBook book;
  final List<String> paragraphs;

  bool get isEmpty => paragraphs.isEmpty;

  @override
  List<Object?> get props => [book.id, paragraphs];
}

/// Everything a share needs, resolved: which verses, out of which surah, and
/// whatever commentary the reader chose to send with them.
///
/// Both outputs are built from this one object — the text share formats it
/// through `buildShareText`, and the image card lays out the same fields — so
/// the two can never disagree about what was shared.
class EAyahShare extends Equatable {
  const EAyahShare({
    required this.surah,
    required this.ayat,
    this.tafsir = const [],
    this.glyphs = const [],
  });

  final MSurah surah;

  /// The verses of the range, in order. Never empty for a resolved share.
  final List<EAyahText> ayat;

  /// Attached books, in the order the reader arranged them.
  final List<EShareTafsir> tafsir;

  /// The same verses as printed glyphs, for the rendered card. Empty when the
  /// Mushaf fonts could not be prepared, which is the card's cue to set the
  /// passage in a text face instead.
  final List<EShareGlyphRun> glyphs;

  int get from => ayat.isEmpty ? 0 : ayat.first.ref.ayah;
  int get to => ayat.isEmpty ? 0 : ayat.last.ref.ayah;
  int get count => ayat.length;

  @override
  List<Object?> get props => [surah.number, ayat, tafsir, glyphs];
}
