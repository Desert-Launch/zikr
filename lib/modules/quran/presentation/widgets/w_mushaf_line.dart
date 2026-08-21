import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/widgets/w_ayah_highlight_text.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';

/// One printed Mushaf line, set at the page's glyph size.
///
/// The QPC-V4 layout is fixed — the words on a line are decided by the printed
/// Mushaf, not by wrapping — so the line cannot be fitted to the page on its
/// own. Instead the *page* solves for one glyph size at which its widest
/// justified line spans the text column exactly (see `printSizeForPage`), hands
/// that down as [baseSize], and every line on the page is set at it. That is
/// what the printed Mushaf does: one size per page, full lines reaching both
/// margins and centred lines falling short — and it is what makes the page fill
/// the width on a tablet as well as on a phone.
///
/// [fontScale] then multiplies it, which is what makes the reader's text-size
/// control real:
///
/// - `1.0` → the printed look, every line on one row.
/// - `<1.0` → smaller glyphs, the lines no longer reach the margins.
///
/// Above `1.0` this widget is not used at all: the line would be wider than the
/// page and wrap, stranding its last word on a row of its own, so the page
/// switches to [WMushafPageReflow]. See [kBigTextThreshold].
///
/// Taps on any word select the whole ayah; a long press opens the bookmark
/// colour picker for it.
class WMushafLine extends StatefulWidget {
  const WMushafLine({
    super.key,
    required this.block,
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
    this.lineHeightBoost = 0,
  });

  final MQpcV4LineBlock block;

  /// The page's printed glyph size at 100%, solved once by the page renderer.
  final double baseSize;

  /// Width of the page's text column, handed down by the page renderer.
  ///
  /// Every line on a page is stretched to the same column, so the page — which
  /// already had to measure that column to solve [baseSize] — passes it in
  /// rather than each line rediscovering it through a `LayoutBuilder` of its
  /// own. Fifteen nested relayout boundaries per page is real work in a scroll,
  /// and all fifteen would have arrived at the same number.
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

  /// Extra leading added on top of the line height [fontScale] alone would ask
  /// for — see [kLandscapeLineHeightBoost], the page's landscape allowance.
  ///
  /// The printed page distributes its slack BETWEEN the lines, so how far apart
  /// they sit is a property of the page, not of the line. On a page whose text
  /// outgrows the viewport there is no slack left to distribute and the boxes
  /// butt together at `height: 1.0` — which is where the tashkeel of one line
  /// start landing in the one above. This puts the leading back inside the line
  /// box, where it survives the page running out of room.
  final double lineHeightBoost;
  final ValueChanged<ParamAyahRef> onSelect;
  final ValueChanged<ParamAyahRef> onLongPress;

  /// Arbitrary size the page's lines are measured at before being solved for
  /// the size that fills the text column. Only the ratio matters — text width
  /// scales linearly with it — so this is a measuring stick, never a rendered
  /// size, and it must NOT track the screen: a device-dependent stick would
  /// cancel out of the ratio anyway.
  static const double measureSize = 28;

  @override
  State<WMushafLine> createState() => _WMushafLineState();
}

/// Natural (unwrapped) width of the printed line [block] at [size], with the
/// ayah-number rosettes it carries.
///
/// Mirrors what [WMushafLine] actually renders: the word glyph runs in
/// [fontFamily] and each ayah's closing rosette in `ayahNumberV4`. The U+200B
/// joiners are omitted — they are zero-width by definition, so they cannot move
/// the total — and colour, selection and the fake-bold shadows are omitted too
/// because none of them touch advance widths.
double mushafLineNaturalWidth(
  MQpcV4LineBlock block, {
  required String fontFamily,
  required double size,
}) {
  final glyphStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w500,
  );
  final markerStyle = TextStyle(
    fontFamily: 'ayahNumberV4',
    fontSize: size,
    height: 1,
  );

  final spans = <InlineSpan>[];
  for (final seg in block.segments) {
    spans.add(TextSpan(text: seg.glyphs, style: glyphStyle));
    if (seg.isAyahEnd) {
      spans.add(
        TextSpan(
          text: '${arabicAyahDigits(seg.ayah)}  ',
          style: markerStyle,
        ),
      );
    }
  }
  if (spans.isEmpty) return 0;

  final painter = TextPainter(
    text: TextSpan(children: spans),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.noScaling,
  )..layout();
  return painter.width;
}

/// U+200B ZERO WIDTH SPACE — a zero-width, shaping-transparent line-break
/// opportunity, used to mark the word boundaries the QPC glyph runs lack.
///
/// Shared with `WMushafPageReflow` so both layouts break in the same places.
const String kQpcWordBreak = '\u200B';

/// How far the highlight pill grows above and below the measured text box, as a
/// fraction of the font size. Shared with `WMushafPageReflow` so a highlighted
/// ayah reads the same in both layouts.
///
/// The pair is lopsided because the box it inflates is: it runs from the font's
/// ascent to its descent, and the QPC glyphs do not sit centred in it. Arabic
/// marks reach far above the ascent, so the top needs real padding to cover
/// them; the descent already sits below the tails, so the bottom needs almost
/// none — and any it gets is spent on the gap to the next printed line.
const double kPillPadTop = 0.40;
const double kPillPadBottom = 0.08;

/// Fake-bold for the QPC page glyphs, as a list of zero-blur shadows.
///
/// `fontWeight` cannot do this job here. The page fonts ship a single weight and
/// are registered at runtime through `FontLoader`, so a request for w800 has no
/// heavier face to resolve to and Skia does not synthesise one — measured on
/// device, w500 and w800 render byte-identical pages. Painting the glyph four
/// more times, offset a hair in each direction and in its own colour, dilates
/// the silhouette instead, which is what "bolder" actually looks like.
///
/// Returns `null` when off so the style keeps its normal single-draw path.
/// The offset is a fraction of the font size, so the weight holds its
/// proportions across the whole text-size range.
List<Shadow>? emboldenShadows({
  required bool bold,
  required Color color,
  required double size,
}) {
  if (!bold) return null;
  final d = size * 0.018;
  return [
    Shadow(color: color, offset: Offset(d, 0)),
    Shadow(color: color, offset: Offset(-d, 0)),
    Shadow(color: color, offset: Offset(0, d)),
    Shadow(color: color, offset: Offset(0, -d)),
  ];
}

/// Line height for a given text [scale].
///
/// 1.0 at 100% keeps the printed page's tight spacing exactly as it is. Above
/// that the leading opens up, because an enlarged line wraps onto extra rows
/// and those rows would otherwise sit right on top of one another.
double _lineHeightFor(double scale) =>
    scale <= 1 ? 1.0 : 1.0 + (scale - 1) * 1.2;

class _WMushafLineState extends State<WMushafLine> {
  /// One tap recognizer per ayah on this line, reused across rebuilds (a fresh
  /// recognizer per build would leak one per frame).
  final Map<String, TapGestureRecognizer> _recognizers = {};

  /// Character ranges of each ayah in the rendered span tree, used to resolve a
  /// long press back to the verse under the finger.
  List<_AyahRange> _ranges = const [];
  TextSpan? _painted;
  double _paintedWidth = 0;
  TextAlign _paintedAlign = TextAlign.center;

  /// Last span tree built, with the inputs that produced it.
  ///
  /// The span tree is the expensive half of a rebuild — grouping the line's
  /// segments, joining the glyph runs and allocating a span per word — and it
  /// depends on none of the things that actually change while the page is on
  /// screen. Selection, playback and bookmarks only move the *highlights*, and
  /// those are re-derived from the cached ranges on every build for the cost of
  /// a loop over the line's two or three ayahs. Only a change to the size, the
  /// font or the ink rebuilds the tree.
  _SpanCache? _cache;

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

  /// Groups consecutive segments by ayah so a whole verse shares one recognizer
  /// and one highlight pill.
  List<_AyahGroup> _groups() {
    final groups = <_AyahGroup>[];
    _AyahGroup? current;
    for (final seg in widget.block.segments) {
      final ref = ParamAyahRef(surah: seg.surah, ayah: seg.ayah);
      if (current == null || current.ref.key != ref.key) {
        current = _AyahGroup(ref: ref);
        groups.add(current);
      }
      current.segments.add(seg);
    }
    return groups;
  }

  /// Returns the line's span tree, rebuilding it only when one of the inputs
  /// that can move it has changed — see [_cache].
  ({TextSpan span, List<_AyahRange> ranges}) _spans(
    double size,
    double lineHeight,
  ) {
    final cached = _cache;
    if (cached != null &&
        cached.size == size &&
        cached.lineHeight == lineHeight &&
        cached.fontFamily == widget.fontFamily &&
        cached.baseColor == widget.baseColor &&
        cached.markerColor == widget.markerColor &&
        cached.bold == widget.bold &&
        identical(cached.block, widget.block)) {
      return (span: cached.span, ranges: cached.ranges);
    }
    final built = _buildSpans(_groups(), size, lineHeight);
    _cache = _SpanCache(
      block: widget.block,
      size: size,
      lineHeight: lineHeight,
      fontFamily: widget.fontFamily,
      baseColor: widget.baseColor,
      markerColor: widget.markerColor,
      bold: widget.bold,
      span: built.span,
      ranges: built.ranges,
    );
    return built;
  }

  /// The tint each ayah on the line currently carries, mapped onto the cached
  /// character ranges. Cheap enough to redo on every build — a line holds two
  /// or three ayahs.
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

  /// Builds the line's span tree at [size], recording each ayah's character
  /// range as it goes.
  ({TextSpan span, List<_AyahRange> ranges}) _buildSpans(
    List<_AyahGroup> groups,
    double size,
    double lineHeight,
  ) {
    final glyphStyle = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: size,
      height: lineHeight,
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
      height: lineHeight,
      color: widget.markerColor,
    );

    final spans = <InlineSpan>[];
    final ranges = <_AyahRange>[];
    var offset = 0;

    for (final group in groups) {
      // Join the words with U+200B ZERO WIDTH SPACE.
      //
      // QPC glyph runs carry no spaces — each word is a pre-shaped PUA run and
      // the spacing is baked into the glyphs — so without this the line breaker
      // has no word boundaries and splits between arbitrary glyphs (visually
      // mid-word). U+200B is a break opportunity of zero width, and Unicode
      // classes it `T` (transparent) in ArabicShaping.txt, so it does not
      // affect shaping or advance widths: the line renders identically, it just
      // becomes breakable in the right places.
      final glyphText = group.segments.map((s) => s.glyphs).join(kQpcWordBreak);
      MQpcV4Segment? endSeg;
      for (final s in group.segments) {
        if (s.isAyahEnd) {
          endSeg = s;
          break;
        }
      }

      // The tap recognizer must sit on the leaf text spans, not a parent: hit
      // testing resolves a tap to the deepest span at that offset, so a parent
      // with only `children` never receives the tap. Each leaf of the ayah gets
      // the same recognizer, so tapping any word (or its rosette) selects the
      // whole ayah.
      final recognizer = _recogniser(group.ref);
      final children = <InlineSpan>[
        TextSpan(text: glyphText, style: glyphStyle, recognizer: recognizer),
      ];
      var len = glyphText.length;
      if (endSeg != null) {
        final markerText = '${arabicAyahDigits(endSeg.ayah)}\u202F\u202F';
        children.add(
          TextSpan(
            text: markerText,
            style: markerStyle,
            recognizer: recognizer,
          ),
        );
        len += markerText.length;
      }

      ranges.add(_AyahRange(ref: group.ref, start: offset, end: offset + len));

      // A break opportunity between ayahs too, so a line can wrap at the seam
      // between two verses and not only inside one.
      if (group != groups.last) {
        children.add(TextSpan(text: kQpcWordBreak, style: glyphStyle));
        len += kQpcWordBreak.length;
      }

      spans.add(TextSpan(children: children));
      offset += len;
    }

    return (span: TextSpan(children: spans), ranges: ranges);
  }

  /// Maps a long press at [local] back to the ayah under the finger.
  void _handleLongPress(Offset local) {
    final span = _painted;
    if (span == null || _ranges.isEmpty) return;
    final painter = TextPainter(
      text: span,
      // Must mirror what was painted, or the hit maps to the wrong verse.
      textAlign: _paintedAlign,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
      // The page stretches every line to its full width, so the rendered text
      // is centred across the page. Without a matching minWidth this painter
      // would collapse to the text's own width and place a short line hard
      // against the start, mapping presses on a surah's last line to the
      // wrong verse.
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
    final maxWidth = widget.maxWidth;
    // One size for the whole page, solved by the page renderer so its widest
    // justified line spans the text column exactly — the printed look at
    // 100% — with the reader's scale applied on top. Fitting each line on
    // its own instead would either stretch a surah's closing line across the
    // page, or (the bug this replaced) refuse to grow any line past a fixed
    // reference and leave a tablet reading with phone-sized text between two
    // fat margins.
    final size = widget.baseSize * widget.fontScale;

    // Line height opens up with the text size: at 100% it stays 1.0 (the
    // tight printed spacing), and grows from there so the extra rows a
    // wrapped line produces are not cramped against each other.
    final lineHeight = _lineHeightFor(widget.fontScale) + widget.lineHeightBoost;

    final built = _spans(size, lineHeight);
    _painted = built.span;
    _ranges = built.ranges;
    _paintedWidth = maxWidth;

    // Always centred — the printed page is centred, and so are the extra
    // rows once a line wraps.
    const align = TextAlign.center;
    _paintedAlign = align;

    // `BoxHeightStyle.max` already grows the highlight box with the line
    // height, so cancel that out of the pill padding — otherwise the tint
    // would balloon past the glyphs as the text size goes up.
    final leading = size * (lineHeight - 1) / 2;
    // Asymmetric on purpose. The measured box spans the font's ascent to
    // its descent, and on a printed Mushaf line those two edges sit very
    // differently against the ink: the tashkeel climb well above the
    // ascent, while the descent already clears the tails underneath. An
    // equal pad on both edges therefore left the marks on the pill's very
    // edge and hung an empty skirt below that reached into the next line.
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: WAyahHighlightText(
          text: built.span,
          ranges: _highlights(built.ranges),
          maxWidth: maxWidth,
          // Grow the pill above/below the glyphs without touching line height.
          padTop: padTop,
          padBottom: padBottom,
          textAlign: align,
        ),
      ),
    );
  }
}

/// A built span tree plus the inputs it was built from — see
/// [_WMushafLineState._cache].
class _SpanCache {
  const _SpanCache({
    required this.block,
    required this.size,
    required this.lineHeight,
    required this.fontFamily,
    required this.baseColor,
    required this.markerColor,
    required this.bold,
    required this.span,
    required this.ranges,
  });

  final MQpcV4LineBlock block;
  final double size;
  final double lineHeight;
  final String fontFamily;
  final Color baseColor;
  final Color markerColor;
  final bool bold;
  final TextSpan span;
  final List<_AyahRange> ranges;
}

/// Selection/playback/bookmark tint for an ayah, by priority: live selection →
/// now-playing → saved bookmark colour. `null` when none apply, so a bookmarked
/// verse always carries its own colour whenever it isn't momentarily selected
/// or being recited.
Color? ayahTint({
  required bool isSelected,
  required bool isPlaying,
  required String? bookmarkHex,
  required bool hasBookmark,
  required Brightness brightness,
}) {
  if (isSelected) {
    return brightness == Brightness.dark
        ? AppColors.surfaceLightGreen.withValues(alpha: 0.22)
        : AppColors.surfaceLightGreen;
  }
  if (isPlaying) return AppColors.accentGoldAmber.withValues(alpha: 0.15);
  if (hasBookmark) return bookmarkHighlightFromHex(bookmarkHex);
  return null;
}

String arabicAyahDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

class _AyahGroup {
  _AyahGroup({required this.ref}) : segments = <MQpcV4Segment>[];
  final ParamAyahRef ref;
  final List<MQpcV4Segment> segments;
}

/// An ayah's character span inside the rendered line.
class _AyahRange {
  const _AyahRange({required this.ref, required this.start, required this.end});
  final ParamAyahRef ref;
  final int start;
  final int end;
}
