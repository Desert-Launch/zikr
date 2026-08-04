import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/widgets/w_ayah_highlight_text.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_line.dart';

/// Text scale above which the reader stops reproducing the printed page and
/// reflows it as one continuous stream (see [WMushafPageReflow]).
///
/// At or below this the page renders line-by-line through [WMushafLine] and is
/// pixel-identical to the printed Mushaf. The cut-off is deliberately a single
/// constant so it can be re-tuned in one place.
const double kBigTextThreshold = 1.5;

/// Whether [scale] should use the reflowed big-text layout.
bool isBigTextScale(double scale) => scale > kBigTextThreshold;

/// Line height used by the reflowed layout.
///
/// Every row here is a genuine wrap, so the leading must clear the QPC glyphs'
/// tashkeel at any size. `height` is a multiple of the font size, so a constant
/// already grows the leading proportionally as the text does — scaling the
/// multiplier too (as the per-line layout does) would compound it into acres of
/// whitespace. 1.6 is exactly what the per-line layout reaches at the threshold,
/// so crossing it doesn't jolt the spacing.
const double _reflowLineHeight = 1.6;

/// A run of consecutive Mushaf lines reflowed as ONE continuous RTL stream.
///
/// The printed QPC-V4 layout fixes which words sit on which line. That is right
/// at print size, but as the text grows each line is fitted and wrapped in
/// isolation, so the words that overflow a line drop onto a fresh row *belonging
/// to that line* — leaving a row holding two words while the rest of the page is
/// full. Above [kBigTextThreshold] this widget dissolves those boundaries: every
/// segment of the run is concatenated into a single span tree and the framework
/// wraps it to the page width, so each row fills to the edge before the next
/// begins and only the run's last row is short.
///
/// A run is a contiguous stretch of [MQpcV4LineBlock]s. Surah headers and
/// basmalas split the page into several runs, so a new surah still starts on its
/// own row.
///
/// Glyph safety: a page's segments all render with the page's single font family
/// (`qcf4_p{page}` and its CPAL variants), resolved once by the page renderer, so
/// merging lines never mixes families. The ayah-number rosette is the one other
/// family, and it is already mixed inside a single printed line.
///
/// Tapping any word selects its whole ayah and a long press opens the bookmark
/// colour picker for it, exactly as in the per-line layout — the ayah grouping
/// survives the merge, and each verse's character range in the merged stream is
/// recorded so a hit can be mapped back to it.
class WMushafPageReflow extends StatefulWidget {
  const WMushafPageReflow({
    super.key,
    required this.blocks,
    required this.selected,
    required this.playing,
    required this.bookmarks,
    required this.fontFamily,
    required this.baseColor,
    required this.markerColor,
    required this.brightness,
    required this.fontScale,
    required this.onSelect,
    required this.onLongPress,
  });

  /// The run's printed lines, in reading order. Their boundaries are dissolved.
  final List<MQpcV4LineBlock> blocks;
  final ParamAyahRef? selected;
  final ParamAyahRef? playing;
  final Map<String, String?> bookmarks;
  final String fontFamily;
  final Color baseColor;
  final Color markerColor;
  final Brightness brightness;
  final double fontScale;
  final ValueChanged<ParamAyahRef> onSelect;
  final ValueChanged<ParamAyahRef> onLongPress;

  @override
  State<WMushafPageReflow> createState() => _WMushafPageReflowState();
}

class _WMushafPageReflowState extends State<WMushafPageReflow> {
  /// One tap recognizer per ayah in the run, reused across rebuilds (a fresh
  /// recognizer per build would leak one per frame).
  final Map<String, TapGestureRecognizer> _recognizers = {};

  /// Character ranges of each ayah in the rendered span tree, used to resolve a
  /// long press back to the verse under the finger.
  List<_AyahRange> _ranges = const [];
  TextSpan? _painted;
  double _paintedWidth = 0;

  /// Always right-aligned in RTL: rows fill from the page edge, and only the
  /// run's last row is allowed to fall short.
  static const TextAlign _align = TextAlign.start;

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recogniser(ParamAyahRef ref) {
    return _recognizers.putIfAbsent(
      ref.key,
      () => TapGestureRecognizer()..onTap = () => widget.onSelect(ref),
    );
  }

  /// Groups every segment of the run by ayah, **across** printed-line
  /// boundaries: a verse split over three printed lines becomes one group, so it
  /// keeps one recognizer, one highlight range and one continuous glyph run.
  List<_AyahGroup> _groups() {
    final groups = <_AyahGroup>[];
    _AyahGroup? current;
    for (final block in widget.blocks) {
      for (final seg in block.segments) {
        final ref = ParamAyahRef(surah: seg.surah, ayah: seg.ayah);
        if (current == null || current.ref.key != ref.key) {
          current = _AyahGroup(ref: ref);
          groups.add(current);
        }
        current.segments.add(seg);
      }
    }
    return groups;
  }

  /// Builds the run's span tree at [size], recording each ayah's character range
  /// as it goes.
  ({TextSpan span, List<AyahHighlight> highlights, List<_AyahRange> ranges})
  _build(List<_AyahGroup> groups, double size) {
    final glyphStyle = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: size,
      height: _reflowLineHeight,
      color: widget.baseColor,
      fontWeight: FontWeight.w500,
    );
    final markerStyle = TextStyle(
      fontFamily: 'ayahNumberV4',
      fontSize: size,
      height: _reflowLineHeight,
      color: widget.markerColor,
    );

    final spans = <InlineSpan>[];
    final highlights = <AyahHighlight>[];
    final ranges = <_AyahRange>[];
    var offset = 0;

    for (final group in groups) {
      // Join the words with U+200B ZERO WIDTH SPACE — never a real space. QPC
      // glyph runs are pre-shaped PUA runs with the spacing baked in, so a space
      // would corrupt them; U+200B adds a zero-width break opportunity at every
      // word boundary without touching shaping or advance widths. Merging the
      // lines is exactly what makes those boundaries matter here: the wrap can
      // now land anywhere in the run, not just inside one printed line.
      final glyphText = group.segments.map((s) => s.glyphs).join(kQpcWordBreak);
      MQpcV4Segment? endSeg;
      for (final s in group.segments) {
        if (s.isAyahEnd) {
          endSeg = s;
          break;
        }
      }

      // The recognizer sits on the LEAF spans: hit testing resolves a tap to the
      // deepest span at that offset, so a parent carrying only `children` would
      // never receive it.
      final recognizer = _recogniser(group.ref);
      final children = <InlineSpan>[
        TextSpan(text: glyphText, style: glyphStyle, recognizer: recognizer),
      ];
      var len = glyphText.length;
      if (endSeg != null) {
        final markerText = '${arabicAyahDigits(endSeg.ayah)}\u202F\u202F';
        children.add(
          TextSpan(text: markerText, style: markerStyle, recognizer: recognizer),
        );
        len += markerText.length;
      }

      final tint = ayahTint(
        isSelected: widget.selected?.key == group.ref.key,
        isPlaying: widget.playing?.key == group.ref.key,
        bookmarkHex: widget.bookmarks[group.ref.key],
        hasBookmark: widget.bookmarks.containsKey(group.ref.key),
        brightness: widget.brightness,
      );
      if (tint != null) {
        highlights.add(
          AyahHighlight(start: offset, end: offset + len, color: tint),
        );
      }
      ranges.add(_AyahRange(ref: group.ref, start: offset, end: offset + len));

      // A break opportunity at the seam between two verses too.
      if (group != groups.last) {
        children.add(TextSpan(text: kQpcWordBreak, style: glyphStyle));
        len += kQpcWordBreak.length;
      }

      spans.add(TextSpan(children: children));
      offset += len;
    }

    return (
      span: TextSpan(children: spans),
      highlights: highlights,
      ranges: ranges,
    );
  }

  /// Maps a long press at [local] back to the ayah under the finger, through the
  /// merged stream's character ranges.
  void _handleLongPress(Offset local) {
    final span = _painted;
    if (span == null || _ranges.isEmpty) return;
    final painter = TextPainter(
      text: span,
      // Must mirror what was painted, or the hit maps to the wrong verse.
      textAlign: _align,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: _paintedWidth);
    final offset = painter.getPositionForOffset(local).offset;
    for (final range in _ranges) {
      if (offset >= range.start && offset < range.end) {
        widget.onLongPress(range.ref);
        return;
      }
    }
    // Past the last glyph (trailing whitespace) — fall back to the last ayah.
    widget.onLongPress(_ranges.last.ref);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    if (groups.isEmpty) return const SizedBox.shrink();

    // No per-line fit here — that is the whole point. The size follows the
    // reader's scale against the same reference the printed layout measures
    // against, so the text is free to outgrow a printed line and wrap.
    final size = WMushafLine.referenceSize * widget.fontScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final built = _build(groups, size);
        _painted = built.span;
        _ranges = built.ranges;
        _paintedWidth = maxWidth;

        // `BoxHeightStyle.max` already grows the highlight box with the line
        // height, so cancel that out of the pill padding — otherwise the tint
        // would balloon past the glyphs as the text size goes up.
        final leading = size * (_reflowLineHeight - 1) / 2;
        final pillPad = (size * 0.36 - leading).clamp(0.0, size * 0.36);

        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onLongPressStart: (d) => _handleLongPress(d.localPosition),
          child: WAyahHighlightText(
            text: built.span,
            ranges: built.highlights,
            maxWidth: maxWidth,
            pad: pillPad,
            textAlign: _align,
          ),
        );
      },
    );
  }
}

class _AyahGroup {
  _AyahGroup({required this.ref}) : segments = <MQpcV4Segment>[];
  final ParamAyahRef ref;
  final List<MQpcV4Segment> segments;
}

/// An ayah's character span inside the merged stream.
class _AyahRange {
  const _AyahRange({required this.ref, required this.start, required this.end});
  final ParamAyahRef ref;
  final int start;
  final int end;
}
