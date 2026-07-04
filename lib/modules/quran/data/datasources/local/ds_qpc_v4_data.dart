import 'dart:convert';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';

/// Loads the bundled QPC-V4 page data (gzipped JSON) and resolves a single page
/// into renderable [MQpcV4Page] blocks.
///
/// Ported from the `quran_library` package's `QpcV4AssetsLoader` +
/// `QpcV4PageRenderer` (GetX stripped). Two gzip JSONs drive it:
/// - `qpc_v4_ayah_info.json.gz` — per-page line layout (line type + word-id range).
/// - `qpc-v4.json.gz` — the glyph text of every word, keyed by word id.
///
/// The store is parsed once (lazily) and cached for the app session. Methods let
/// exceptions bubble; the repository converts them to [Failure] (CLAUDE.md §6).
class DSQpcV4Data {
  DSQpcV4Data();

  static const _ayahInfoAsset = 'assets/data/qpc_v4/qpc_v4_ayah_info.json.gz';
  static const _wordsAsset = 'assets/data/qpc_v4/qpc-v4.json.gz';

  Map<int, _QpcV4Word>? _wordsById;
  Map<int, List<_QpcV4AyahInfoLine>>? _linesByPage;
  Future<void>? _loading;

  /// Ensures the gzip JSON stores are decoded and indexed (once per session).
  Future<void> _ensureLoaded() {
    if (_wordsById != null && _linesByPage != null) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final ayahInfo = await _decodeGzJson(_ayahInfoAsset);
    if (ayahInfo is! List) {
      throw const FormatException('qpc_v4_ayah_info.json must be a JSON List');
    }
    final linesByPage = <int, List<_QpcV4AyahInfoLine>>{};
    for (final item in ayahInfo) {
      if (item is! Map) continue;
      final line = _QpcV4AyahInfoLine.fromJson(Map<String, dynamic>.from(item));
      (linesByPage[line.pageNumber] ??= <_QpcV4AyahInfoLine>[]).add(line);
    }
    for (final lines in linesByPage.values) {
      lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    }

    final words = await _decodeGzJson(_wordsAsset);
    if (words is! Map) {
      throw const FormatException('qpc-v4.json must be a JSON Map');
    }
    final wordsById = <int, _QpcV4Word>{};
    for (final value in words.values) {
      if (value is! Map) continue;
      final word = _QpcV4Word.fromJson(Map<String, dynamic>.from(value));
      wordsById[word.id] = word;
    }

    _linesByPage = linesByPage;
    _wordsById = wordsById;
  }

  Future<dynamic> _decodeGzJson(String asset) async {
    final data = await rootBundle.load(asset);
    final gz = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final bytes = const GZipDecoder().decodeBytes(gz);
    return jsonDecode(utf8.decode(bytes));
  }

  /// Resolves [page] (1-based) into ordered render blocks.
  Future<MQpcV4Page> loadPage(int page) async {
    await _ensureLoaded();
    final lines = _linesByPage?[page];
    if (lines == null || lines.isEmpty) {
      return MQpcV4Page(page: page, blocks: const []);
    }
    return MQpcV4Page(page: page, blocks: _buildBlocks(lines));
  }

  // --- Page rendering (ported from QpcV4PageRenderer) -----------------------

  int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;

  /// Synthetic unique ayah id. Any non-zero value works — it only groups the
  /// words of one ayah for selection.
  int _ayahUq(int surah, int ayah) => surah * 1000 + ayah;

  List<MQpcV4Block> _buildBlocks(List<_QpcV4AyahInfoLine> lines) {
    final words = _wordsById ?? const {};
    final endMaps = _buildAyahEndMaps(lines, words);
    final endWordIdByAyahKey = endMaps.$1;
    final maxWordIndexByAyahKey = endMaps.$2;

    final blocks = <MQpcV4Block>[];
    var needsSingleSpaceAtPageStart = true;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      switch (line.lineType) {
        case QpcV4LineType.surahName:
          if (line.surahNumber != null) {
            blocks.add(MQpcV4SurahHeaderBlock(line.surahNumber!));
          }
          break;
        case QpcV4LineType.basmala:
          final inferred = _inferBasmalaSurah(lines, i, words);
          if (inferred != null) blocks.add(MQpcV4BasmalaBlock(inferred));
          break;
        case QpcV4LineType.ayah:
          final start = line.firstWordId;
          final end = line.lastWordId;
          if (start == null || end == null) break;
          final result = _buildAyahSegmentsForLine(
            rangeStart: start,
            rangeEnd: end,
            words: words,
            endWordIdByAyahKey: endWordIdByAyahKey,
            maxWordIndexByAyahKey: maxWordIndexByAyahKey,
            addSingleSpaceBetweenFirstTwoWords: needsSingleSpaceAtPageStart,
          );
          if (result.$1.isNotEmpty) {
            blocks.add(
              MQpcV4LineBlock(isCentered: line.isCentered, segments: result.$1),
            );
          }
          if (result.$2) needsSingleSpaceAtPageStart = false;
          break;
      }
    }
    return blocks;
  }

  (Map<int, int>, Map<int, int>) _buildAyahEndMaps(
    List<_QpcV4AyahInfoLine> lines,
    Map<int, _QpcV4Word> words,
  ) {
    final lastWordIdSeenByAyahKey = <int, int>{};
    final maxWordIndexByAyahKey = <int, int>{};

    for (final line in lines) {
      if (line.lineType != QpcV4LineType.ayah) continue;
      final start = line.firstWordId;
      final end = line.lastWordId;
      if (start == null || end == null) continue;
      for (var wordId = start; wordId <= end; wordId++) {
        final w = words[wordId];
        if (w == null) continue;
        final key = _ayahKey(w.surah, w.ayah);
        lastWordIdSeenByAyahKey[key] = wordId;
        final prevMax = maxWordIndexByAyahKey[key];
        if (prevMax == null || w.wordIndex > prevMax) {
          maxWordIndexByAyahKey[key] = w.wordIndex;
        }
      }
    }

    // QPC files append a trailing element per (surah/ayah) that carries the ayah
    // number. Treat it as the highest wordIndex and end the ayah on the last
    // real word before it.
    final endWordIdByAyahKey = <int, int>{};
    for (final entry in lastWordIdSeenByAyahKey.entries) {
      final key = entry.key;
      final lastWordId = entry.value;
      final maxIndex = maxWordIndexByAyahKey[key];
      if (maxIndex == null) {
        endWordIdByAyahKey[key] = lastWordId;
        continue;
      }
      var effectiveEnd = lastWordId;
      while (effectiveEnd > 0) {
        final w = words[effectiveEnd];
        if (w == null) break;
        if (_ayahKey(w.surah, w.ayah) != key) break;
        if (w.wordIndex != maxIndex) break;
        effectiveEnd -= 1;
      }
      endWordIdByAyahKey[key] = effectiveEnd > 0 ? effectiveEnd : lastWordId;
    }

    return (endWordIdByAyahKey, maxWordIndexByAyahKey);
  }

  (List<MQpcV4Segment>, bool) _buildAyahSegmentsForLine({
    required int rangeStart,
    required int rangeEnd,
    required Map<int, _QpcV4Word> words,
    required Map<int, int> endWordIdByAyahKey,
    required Map<int, int> maxWordIndexByAyahKey,
    required bool addSingleSpaceBetweenFirstTwoWords,
  }) {
    final segments = <MQpcV4Segment>[];
    var didInsertSingleSpace = false;
    var realWordsWritten = 0;

    for (var wordId = rangeStart; wordId <= rangeEnd; wordId++) {
      final w = words[wordId];
      if (w == null) continue;
      final key = _ayahKey(w.surah, w.ayah);

      // Drop the trailing "ayah number" element (highest wordIndex).
      final maxIndex = maxWordIndexByAyahKey[key];
      if (maxIndex != null && w.wordIndex == maxIndex) continue;

      final uq = _ayahUq(w.surah, w.ayah);
      final endWordId = endWordIdByAyahKey[key];
      final isAyahEnd = endWordId != null && wordId == endWordId;

      final resolvedText = w.text;
      if (resolvedText.isEmpty) continue;

      // Targeted fix: insert one narrow no-break space between the first two
      // real words of the page's first ayah line (matches the package).
      if (addSingleSpaceBetweenFirstTwoWords && realWordsWritten == 0) {
        final runes = resolvedText.runes.toList(growable: false);
        final glyphs =
            '${String.fromCharCode(runes.first)}\u202F${String.fromCharCodes(runes.skip(1))}';
        didInsertSingleSpace = true;
        segments.add(MQpcV4Segment(
          wordId: w.id,
          ayahUq: uq,
          surah: w.surah,
          ayah: w.ayah,
          wordNumber: w.wordIndex,
          glyphs: glyphs,
          isAyahEnd: isAyahEnd,
        ));
        realWordsWritten += 2;
        continue;
      }

      var glyphs = resolvedText;
      if (addSingleSpaceBetweenFirstTwoWords && realWordsWritten == 1) {
        glyphs = '\u202F$glyphs';
        didInsertSingleSpace = true;
      }

      segments.add(MQpcV4Segment(
        wordId: w.id,
        ayahUq: uq,
        surah: w.surah,
        ayah: w.ayah,
        wordNumber: w.wordIndex,
        glyphs: glyphs,
        isAyahEnd: isAyahEnd,
      ));
      realWordsWritten++;
    }
    return (segments, didInsertSingleSpace);
  }

  int? _inferBasmalaSurah(
    List<_QpcV4AyahInfoLine> lines,
    int index,
    Map<int, _QpcV4Word> words,
  ) {
    for (var i = index + 1; i < lines.length; i++) {
      final next = lines[i];
      if (next.lineType != QpcV4LineType.ayah) continue;
      final start = next.firstWordId;
      if (start == null) continue;
      return words[start]?.surah;
    }
    return null;
  }
}

// --- Internal parse models --------------------------------------------------

int? _tryParseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

class _QpcV4AyahInfoLine {
  const _QpcV4AyahInfoLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.surahNumber,
    required this.firstWordId,
    required this.lastWordId,
  });

  final int pageNumber;
  final int lineNumber;
  final QpcV4LineType lineType;
  final bool isCentered;
  final int? surahNumber;
  final int? firstWordId;
  final int? lastWordId;

  factory _QpcV4AyahInfoLine.fromJson(Map<String, dynamic> json) {
    return _QpcV4AyahInfoLine(
      pageNumber: (json['page_number'] as num).toInt(),
      lineNumber: (json['line_number'] as num).toInt(),
      lineType: QpcV4LineType.fromJson(json['line_type']),
      isCentered: ((json['is_centered'] as num?)?.toInt() ?? 0) == 1,
      surahNumber: _tryParseOptionalInt(json['surah_number']),
      firstWordId: _tryParseOptionalInt(json['first_word_id']),
      lastWordId: _tryParseOptionalInt(json['last_word_id']),
    );
  }
}

class _QpcV4Word {
  const _QpcV4Word({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.text,
  });

  final int id;
  final int surah;
  final int ayah;
  final int wordIndex;
  final String text;

  factory _QpcV4Word.fromJson(Map<String, dynamic> json) {
    return _QpcV4Word(
      id: (json['id'] as num).toInt(),
      surah: int.parse(json['surah'].toString()),
      ayah: int.parse(json['ayah'].toString()),
      wordIndex: int.parse(json['word'].toString()),
      text: (json['text'] ?? '').toString(),
    );
  }
}
