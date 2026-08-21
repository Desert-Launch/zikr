import 'package:flutter/foundation.dart' show listEquals;
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
///
/// It sits at 1.0 — the printed size — because that is precisely where the
/// per-line layout stops working. Each printed line is fitted to span the page
/// exactly at 100%, so *any* enlargement pushes it past the width and it wraps,
/// dropping its last word or two onto a row of their own. At 120% that happened
/// on nearly every line and the page read as a column of orphans. Reflow has no
/// such cliff, so everything above print size goes through it.
const double kBigTextThreshold = 1.0;

/// Whether [scale] should use the reflowed big-text layout.
///
/// The epsilon keeps a continuous slider that lands a hair over 1.0 (or a value
/// that survived a float round-trip through storage) on the printed layout,
/// where it belongs — the difference is invisible, the layout switch is not.
bool isBigTextScale(double scale) => scale > kBigTextThreshold + 0.005;

/// Word separator in the reflowed layout: a real U+0020 SPACE, not the U+200B
/// the printed layout uses.
///
/// The printed layout needs no separator width at all — a QPC line is a
/// pre-shaped run whose spacing is baked into the glyphs *for the width that
/// line was set at*, and the reader reproduces it by scaling the whole line.
/// Reflow throws that away: it breaks the run at word boundaries and re-packs
/// the words to a new width, so whatever sits between two words is the only
/// spacing there is.
///
/// It has to be real whitespace because that is the only thing justification
/// can stretch — Flutter distributes a row's slack across its whitespace
/// clusters, and U+200B is category Cf, so a row joined with it can never be
/// justified and always ends short of the margin. A space is safe here where it
/// would not be inside a word: the QPC glyphs are Private Use codepoints with no
/// Arabic joining behaviour, so nothing either side of it reshapes.
const String _kReflowWordSpace = ' ';

/// Extra width added to each word space, as a fraction of the font size.
///
/// This is the floor, not the final gap: justification opens the spaces further
/// to reach the margin. It only shows as-is on a run's last row, which is the
/// one row justification leaves alone — so it is tuned to match what the
/// justified rows above it settle at.
const double _kExtraWordSpacing = 0.06;

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
    required this.baseSize,
    required this.maxWidth,
    required this.selected,
    required this.playing,
    required this.bookmarks,
    required this.fontFamily,
    required this.baseColor,
    required this.markerColor,
    required this.brightness,
    required this.fontScale,
    required this.bold,
    required this.onSelect,
    required this.onLongPress,
  });

  /// The run's printed lines, in reading order. Their boundaries are dissolved.
  final List<MQpcV4LineBlock> blocks;

  /// The page's printed glyph size at 100% — the same one [WMushafLine] is set
  /// at, so crossing [kBigTextThreshold] changes the line breaking and nothing
  /// else. Deriving it from a fixed reference instead made the text jump a size
  /// at the threshold on any screen the page had to grow to fill.
  final double baseSize;

  /// Width of the page's text column, handed down by the page renderer — the
  /// same bound [WMushafLine] is given, and for the same reason: the page has
  /// already measured it, so a `LayoutBuilder` here would only rediscover it.
  final double maxWidth;
  final ParamAyahRef? selected;
  final ParamAyahRef? playing;
  final Map<String, String?> bookmarks;
  final String fontFamily;
  final Color baseColor;
  final Color markerColor;
  final Brightness brightness;
  final double fontScale;

  /// Heavier glyph weight, from the reader's text settings.
  final bool bold;
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

  /// Last span tree built, with the inputs that produced it — the run's stream
  /// is far more expensive to assemble than a single printed line, and none of
  /// selection, playback or bookmarks can change it. See
  /// `_WMushafLineState._cache`.
  _ReflowSpanCache? _cache;

  /// Justified, like the printed Mushaf.
  ///
  /// Wrapping alone only guarantees a row does not *exceed* the width; where it
  /// actually ends is wherever the next word stopped fitting, so the rows come
  /// out ragged by up to a word. Justifying spreads each row's leftover width
  /// across its spaces instead, so every row reaches both margins — which is
  /// what the printed page does, and the reason the separator has to be real
  /// whitespace (see [_kReflowWordSpace]).
  ///
  /// The one row this leaves alone is the last of each run, which keeps its
  /// natural spacing and sits against the start edge — the same thing a printed
  /// page does with the line that ends a surah.
  static const TextAlign _align = TextAlign.justify;

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

  /// Returns the run's span tree, rebuilding it only when one of the inputs
  /// that can move it has changed — see [_cache].
  ({TextSpan span, List<_AyahRange> ranges}) _spans(double size) {
    final cached = _cache;
    if (cached != null &&
        cached.size == size &&
        cached.fontFamily == widget.fontFamily &&
        cached.baseColor == widget.baseColor &&
        cached.markerColor == widget.markerColor &&
        cached.bold == widget.bold &&
        listEquals(cached.blocks, widget.blocks)) {
      return (span: cached.span, ranges: cached.ranges);
    }
    final built = _buildSpans(_groups(), size);
    _cache = _ReflowSpanCache(
      blocks: widget.blocks,
      size: size,
      fontFamily: widget.fontFamily,
      baseColor: widget.baseColor,
      markerColor: widget.markerColor,
      bold: widget.bold,
      span: built.span,
      ranges: built.ranges,
    );
    return built;
  }

  /// The tint each ayah in the run currently carries, mapped onto the cached
  /// character ranges.
  List<AyahHighlight> _highlights(List<_AyahRange> ranges) {
    final highlights = <AyahHighlight>[];
    for (final range in ranges) {
      final tint = ayahTint(
        isSelected: widget.selected?.key == range.ref.key,
        isPlaying: widget.playing?.key == range.ref.key,
        bookmarkHex: widget.bookmarks[range.ref.key],
        hasBookmark: widget.bookmarks.containsKey(range.ref.key),
        brightness: widget.brightness,
      );
      if (tint != null) {
        highlights.add(
          AyahHighlight(start: range.start, end: range.end, color: tint),
        );
      }
    }
    return highlights;
  }

  /// Builds the run's span tree at [size], recording each ayah's character range
  /// as it goes.
  ({TextSpan span, List<_AyahRange> ranges}) _buildSpans(
    List<_AyahGroup> groups,
    double size,
  ) {
    final glyphStyle = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: size,
      height: _reflowLineHeight,
      color: widget.baseColor,
      fontWeight: FontWeight.w500,
      shadows: emboldenShadows(
        bold: widget.bold,
        color: widget.baseColor,
        size: size,
      ),
    );
    final markerStyle = TextStyle(
      fontFamily: 'ayahNumberV4',
      fontSize: size,
      height: _reflowLineHeight,
      color: widget.markerColor,
    );
    // The word space. `wordSpacing` widens U+0020 specifically, so it can sit on
    // the same style the words use without touching the letters inside them —
    // unlike `letterSpacing`, which would push every glyph of every word apart
    // and take the Arabic script's joining with it.
    final spacerStyle = glyphStyle.copyWith(
      wordSpacing: size * _kExtraWordSpacing,
    );

    final spans = <InlineSpan>[];
    final ranges = <_AyahRange>[];
    var offset = 0;

    for (final group in groups) {
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
      final children = <InlineSpan>[];
      var len = 0;

      // One span per word, separated by U+200B ZERO WIDTH SPACE — never a real
      // space. QPC glyph runs are pre-shaped PUA runs with the spacing baked in,
      // so a space would corrupt them; U+200B is a break opportunity Unicode
      // classes as transparent (`T` in ArabicShaping.txt), so it neither joins
      // nor separates the letters either side of it. Merging the printed lines
      // is what makes those boundaries matter here — the wrap can now land
      // anywhere in the run, not just inside one printed line — and the joiner
      // carries the word gap the discarded printed spacing used to provide.
      for (var i = 0; i < group.segments.length; i++) {
        final word = group.segments[i].glyphs;
        children.add(
          TextSpan(text: word, style: glyphStyle, recognizer: recognizer),
        );
        len += word.length;
        if (i < group.segments.length - 1) {
          children.add(
            TextSpan(
              text: _kReflowWordSpace,
              style: spacerStyle,
              recognizer: recognizer,
            ),
          );
          len += _kReflowWordSpace.length;
        }
      }

      if (endSeg != null) {
        // The rosette gets the same gap in front of it as any other word.
        children.add(
          TextSpan(
            text: _kReflowWordSpace,
            style: spacerStyle,
            recognizer: recognizer,
          ),
        );
        len += _kReflowWordSpace.length;
        final markerText = '${arabicAyahDigits(endSeg.ayah)}\u202F\u202F';
        children.add(
          TextSpan(text: markerText, style: markerStyle, recognizer: recognizer),
        );
        len += markerText.length;
      }

      ranges.add(_AyahRange(ref: group.ref, start: offset, end: offset + len));

      // A break opportunity at the seam between two verses too.
      if (group != groups.last) {
        children.add(TextSpan(text: _kReflowWordSpace, style: spacerStyle));
        len += _kReflowWordSpace.length;
      }

      spans.add(TextSpan(children: children));
      offset += len;
    }

    return (span: TextSpan(children: spans), ranges: ranges);
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
      // Matches the rendered width, not the text's own — see the same layout
      // call in [WMushafLine].
    )..layout(minWidth: _paintedWidth, maxWidth: _paintedWidth);
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
    if (widget.blocks.every((b) => b.segments.isEmpty)) {
      return const SizedBox.shrink();
    }

    // No per-line fit here — that is the whole point. The size is the page's
    // printed size scaled by the reader, so the text picks up exactly where the
    // printed layout left off at 100% and is then free to outgrow a printed
    // line and wrap.
    final size = widget.baseSize * widget.fontScale;

    final maxWidth = widget.maxWidth;
    final built = _spans(size);
    _painted = built.span;
    _ranges = built.ranges;
    _paintedWidth = maxWidth;

    // `BoxHeightStyle.max` already grows the highlight box with the line
    // height, so cancel that out of the pill padding — otherwise the tint
    // would balloon past the glyphs as the text size goes up.
    final leading = size * (_reflowLineHeight - 1) / 2;
    // Lopsided for the same reason as the printed layout — see
    // [kPillPadTop] / [kPillPadBottom]. The generous leading here eats most
    // of it, which is why a reflowed page needs so little extra.
    final padTop = (size * kPillPadTop - leading).clamp(
      0.0,
      size * kPillPadTop,
    );
    final padBottom = (size * kPillPadBottom - leading).clamp(
      0.0,
      size * kPillPadBottom,
    );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (d) => _handleLongPress(d.localPosition),
      child: WAyahHighlightText(
        text: built.span,
        ranges: _highlights(built.ranges),
        maxWidth: maxWidth,
        padTop: padTop,
        padBottom: padBottom,
        textAlign: _align,
      ),
    );
  }
}

/// A built reflow span tree plus the inputs it was built from — see
/// [_WMushafPageReflowState._cache].
class _ReflowSpanCache {
  const _ReflowSpanCache({
    required this.blocks,
    required this.size,
    required this.fontFamily,
    required this.baseColor,
    required this.markerColor,
    required this.bold,
    required this.span,
    required this.ranges,
  });

  final List<MQpcV4LineBlock> blocks;
  final double size;
  final String fontFamily;
  final Color baseColor;
  final Color markerColor;
  final bool bold;
  final TextSpan span;
  final List<_AyahRange> ranges;
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
