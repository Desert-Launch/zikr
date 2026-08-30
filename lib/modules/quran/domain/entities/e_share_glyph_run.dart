import 'package:equatable/equatable.dart';

/// One printed word of a shared passage, in the Mushaf's own hand.
///
/// The QPC glyph runs are Private Use codepoints with no meaning outside the
/// font of the page they came from, so [fontFamily] travels with the run rather
/// than being worked out again where it is drawn: it names the family the data
/// layer actually registered, which is the only one that can render [glyphs].
class EShareGlyphRun extends Equatable {
  const EShareGlyphRun({
    required this.fontFamily,
    required this.glyphs,
    required this.ayah,
    required this.isAyahEnd,
  });

  final String fontFamily;

  /// Pre-shaped glyph run for one word. Carries no spaces — the spacing is
  /// baked into the glyphs.
  final String glyphs;

  final int ayah;

  /// True on the last word of a verse, where the numbered rosette goes.
  final bool isAyahEnd;

  @override
  List<Object?> get props => [fontFamily, glyphs, ayah, isAyahEnd];
}
