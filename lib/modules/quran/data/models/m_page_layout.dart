import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// A single word inside a line of a mushaf page.
class MWord extends Equatable {
  const MWord({
    required this.location,
    required this.word,
    required this.qpcV1,
    this.qpcV2,
    this.qpcV4,
    this.charType = 'word',
  });

  factory MWord.fromJson(Map<String, dynamic> json) => MWord(
        location: json['location'] as String? ?? '',
        word: json['word'] as String? ?? '',
        qpcV1: json['qpcV1'] as String? ?? '',
        qpcV2: json['qpcV2'] as String?,
        qpcV4: json['qpcV4'] as String?,
        charType: json['charType'] as String? ?? 'word',
      );

  /// "S:V:W" — surah:ayah:word index. e.g. "1:1:3".
  final String location;
  final String word;
  /// QPC V1 glyph for this word (PUA codepoints — render with the per-page font).
  final String qpcV1;
  final String? qpcV2;
  /// QPC V4 tajweed (coloured) glyph(s) for this word — render with the V4
  /// per-page colour font. Present only in the V4 dataset.
  final String? qpcV4;
  /// 'word' or 'end' (ayah-end marker glyph). From the V4 dataset.
  final String charType;

  int get surah => int.tryParse(location.split(':').first) ?? 0;
  int get ayah => int.tryParse(location.split(':').elementAt(1)) ?? 0;

  @override
  List<Object?> get props => [location];
}

enum LineType { text, surahHeader, basmala, spacer }

class MLine extends Equatable {
  const MLine({
    required this.line,
    required this.type,
    required this.text,
    this.verseRange,
    this.surahNumber,
    this.fontPage,
    this.words = const [],
  });

  factory MLine.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? 'text').toLowerCase();
    final type = switch (rawType) {
      'surah-header' || 'surah_header' || 'surah' => LineType.surahHeader,
      'basmala' || 'bismillah' => LineType.basmala,
      'spacer' || 'space' => LineType.spacer,
      _ => LineType.text,
    };
    final words = (json['words'] as List<dynamic>?)
            ?.map((w) => MWord.fromJson(Map<String, dynamic>.from(w as Map)))
            .toList(growable: false) ??
        const <MWord>[];
    return MLine(
      line: json['line'] as int? ?? 0,
      type: type,
      text: json['text'] as String? ?? '',
      verseRange: json['verseRange'] as String?,
      surahNumber: int.tryParse(json['surah']?.toString() ?? ''),
      fontPage: json['fontPage'] as int?,
      words: words,
    );
  }

  final int line;
  final LineType type;
  final String text;
  /// e.g. "2:1-2:5"
  final String? verseRange;
  final int? surahNumber;
  /// QPC font page whose glyph set this line's [words] belong to, when it
  /// differs from the mushaf page the line is printed on. A handful of pages
  /// carry a top line whose QPC v2 glyph codes live in the *previous* page's
  /// font; those lines set this so the renderer picks the font that actually
  /// contains their glyphs. `null` (the norm) means use the page's own font.
  final int? fontPage;
  final List<MWord> words;

  /// Unique ayah refs touched by this line (in order, no duplicates).
  List<ParamAyahRef> get ayahRefs {
    if (words.isEmpty) return const [];
    final seen = <String>{};
    final out = <ParamAyahRef>[];
    for (final w in words) {
      final ref = ParamAyahRef(surah: w.surah, ayah: w.ayah);
      if (seen.add(ref.key)) out.add(ref);
    }
    return out;
  }

  @override
  List<Object?> get props => [line, type, text];
}

class MPageLayout extends Equatable {
  const MPageLayout({required this.page, required this.lines});

  factory MPageLayout.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>?)
            ?.map((l) => MLine.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(growable: false) ??
        const <MLine>[];
    return MPageLayout(page: json['page'] as int? ?? 0, lines: lines);
  }

  final int page;
  final List<MLine> lines;

  /// All ayah refs that appear anywhere on this page.
  List<ParamAyahRef> get allAyahRefs {
    final seen = <String>{};
    final out = <ParamAyahRef>[];
    for (final l in lines) {
      for (final r in l.ayahRefs) {
        if (seen.add(r.key)) out.add(r);
      }
    }
    return out;
  }

  @override
  List<Object?> get props => [page];
}
