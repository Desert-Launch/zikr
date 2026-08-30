import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// One ayah paired with its plain Uthmani text.
///
/// The rendered Mushaf uses QPC glyph fonts whose codepoints are private-use
/// and unreadable outside the app, so anything that has to leave the reader —
/// a copy, a share, a search snippet — needs the text in real Arabic letters.
class EAyahText extends Equatable {
  const EAyahText({required this.ref, required this.text});

  final ParamAyahRef ref;

  /// Uthmani text, without the trailing ayah-number rosette.
  final String text;

  @override
  List<Object?> get props => [ref, text];
}
