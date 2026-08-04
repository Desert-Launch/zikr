import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/widgets/w_ayah_highlight_text.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';

/// One printed Mushaf line, sized to the page.
///
/// The QPC-V4 layout is fixed — the words on a line are decided by the printed
/// Mushaf, not by wrapping — so the line is measured and scaled to exactly fill
/// the page width. That fitted size is the 100% reference; [fontScale] then
/// multiplies it, which is what makes the reader's text-size control real:
///
/// - `1.0` → the line fills the width exactly (one row, the printed look).
/// - `<1.0` → smaller glyphs, the line no longer reaches the edges.
/// - `>1.0` → bigger glyphs; the line is wider than the page so it wraps onto a
///   second row and the page grows taller (the page scrolls — see
///   [WMushafV4Page]). The Mushaf's own line breaks are preserved: each printed
///   line is still one widget.
///
/// Taps on any word select the whole ayah; a long press opens the bookmark
/// colour picker for it.
class WMushafLine extends StatefulWidget {
  const WMushafLine({
    super.key,
    required this.block,
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

  final MQpcV4LineBlock block;
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

  /// Intrinsic glyph size the line is measured at before being fitted to the
  /// page width. Only the ratio matters — text width scales linearly with it.
  static double get referenceSize => 28.sp;

  @override
  State<WMushafLine> createState() => _WMushafLineState();
}

/// U+200B ZERO WIDTH SPACE — a zero-width, shaping-transparent line-break
/// opportunity, used to mark the word boundaries the QPC glyph runs lack.
///
/// Shared with `WMushafPageReflow` so both layouts break in the same places.
const String kQpcWordBreak = '\u200B';

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

  /// Cached natural width of the line at the reference size. It depends only on
  /// the glyphs and the font family — not on colour, selection or scale — so it
  /// survives the rebuilds those trigger and the measuring layout runs once per
  /// font change instead of once per frame.
  double? _naturalWidth;
  String? _measuredFamily;

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

  /// Builds the line's span tree at [size], recording each ayah's character
  /// range as it goes.
  ({TextSpan span, List<AyahHighlight> highlights, List<_AyahRange> ranges})
  _build(List<_AyahGroup> groups, double size, double lineHeight) {
    final glyphStyle = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: size,
      height: lineHeight,
      color: widget.baseColor,
      fontWeight: FontWeight.w500,
    );
    final markerStyle = TextStyle(
      fontFamily: 'ayahNumberV4',
      fontSize: size,
      height: lineHeight,
      color: widget.markerColor,
    );

    final spans = <InlineSpan>[];
    final highlights = <AyahHighlight>[];
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

      // A break opportunity between ayahs too, so a line can wrap at the seam
      // between two verses and not only inside one.
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

  /// Natural (unwrapped) width of the line at [WMushafLine.referenceSize].
  double _naturalWidthAt(List<_AyahGroup> groups, double reference) {
    final cached = _naturalWidth;
    if (cached != null && _measuredFamily == widget.fontFamily) return cached;
    final painter = TextPainter(
      text: _build(groups, reference, 1).span,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout();
    _naturalWidth = painter.width;
    _measuredFamily = widget.fontFamily;
    return painter.width;
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
    final reference = WMushafLine.referenceSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Measure once at the reference size, then solve for the size that fits
        // the page width. Never upscale past the reference — short lines (surah
        // openers, the last line of a surah) keep their printed proportions
        // instead of being stretched across the page.
        // Solve for the size that makes this line span the page width exactly —
        // that is 100%, the printed look — then apply the reader's scale on top.
        final natural = _naturalWidthAt(groups, reference);
        final fit = natural <= 0
            ? 1.0
            // Short lines (surah openers, a surah's last line) are not stretched
            // across the page; they keep their printed proportions.
            : (maxWidth * 0.995 / natural).clamp(0.0, 1.0);
        final size = reference * fit * widget.fontScale;

        // Line height opens up with the text size: at 100% it stays 1.0 (the
        // tight printed spacing), and grows from there so the extra rows a
        // wrapped line produces are not cramped against each other.
        final lineHeight = _lineHeightFor(widget.fontScale);

        final built = _build(groups, size, lineHeight);
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
        final pillPad = (size * 0.36 - leading).clamp(0.0, size * 0.36);

        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onLongPressStart: (d) => _handleLongPress(d.localPosition),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: WAyahHighlightText(
              text: built.span,
              ranges: built.highlights,
              maxWidth: maxWidth,
              // Grow the pill above/below the glyphs without touching line height.
              pad: pillPad,
              textAlign: align,
            ),
          ),
        );
      },
    );
  }
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
