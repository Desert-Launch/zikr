import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A highlighted character range inside a laid-out span tree, with its fill.
@immutable
class AyahHighlight {
  const AyahHighlight({
    required this.start,
    required this.end,
    required this.color,
  });

  /// Inclusive start / exclusive end offsets into the concatenated plain text
  /// of the span tree (WidgetSpans count as one character).
  final int start;
  final int end;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is AyahHighlight &&
      other.start == start &&
      other.end == end &&
      other.color == color;

  @override
  int get hashCode => Object.hash(start, end, color);
}

/// Renders [text] as an RTL [RichText] and paints a rounded highlight pill
/// BEHIND the given [ranges], grown by [padTop] above and [padBottom] below.
///
/// The whole point: the highlight can read taller than the glyphs without
/// touching the text's line-height, so line spacing stays tight. The pill is
/// measured by re-laying-out an identical [TextPainter] under the same
/// constraints as the child, so its boxes line up exactly with the rendered
/// text. Taps still land on the child's span recognizers (the painter draws
/// behind and never intercepts hits).
///
/// The two pads are separate because the measured box is not centred on the
/// glyphs: it runs from the font's ascent to its descent, and Arabic tashkeel
/// sit *above* that ascent while the descent already clears the tails. Padding
/// both edges equally therefore leaves the marks barely covered and spills a
/// tall skirt of tint onto the next printed line.
class WAyahHighlightText extends StatelessWidget {
  const WAyahHighlightText({
    required this.text,
    required this.ranges,
    required this.padTop,
    required this.padBottom,
    this.textAlign = TextAlign.start,
    this.maxWidth,
    this.radius = 8,
    super.key,
  });

  final TextSpan text;
  final List<AyahHighlight> ranges;

  /// Vertical inflation (logical px) added above each highlight box.
  final double padTop;

  /// Vertical inflation (logical px) added below each highlight box.
  final double padBottom;
  final TextAlign textAlign;

  /// Width bound fed to the measuring painter — pass the same bound the child
  /// RichText gets (a fixed width, or null for the child's natural width).
  final double? maxWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Wrapping is allowed: [WMushafLine] separates the QPC word-glyph runs with
    // U+200B so the only break opportunities are real word boundaries. At 100%
    // the line is sized to fit one row and never wraps anyway.
    final child = RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: text,
    );
    if (ranges.isEmpty) return child;
    return CustomPaint(
      painter: _HighlightPainter(
        text: text,
        ranges: ranges,
        padTop: padTop,
        padBottom: padBottom,
        radius: radius,
        textAlign: textAlign,
        maxWidth: maxWidth,
      ),
      child: child,
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.text,
    required this.ranges,
    required this.padTop,
    required this.padBottom,
    required this.radius,
    required this.textAlign,
    required this.maxWidth,
  });

  final TextSpan text;
  final List<AyahHighlight> ranges;
  final double padTop;
  final double padBottom;
  final double radius;
  final TextAlign textAlign;
  final double? maxWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Mirror the child RichText exactly: same spans, direction, align, and the
    // RichText default (no text scaling), so measured boxes match the glyphs.
    //
    // `minWidth` is the part that is easy to miss. A TextPainter given only a
    // maxWidth shrinks to the text's intrinsic width, and `textAlign` then
    // centres the glyphs inside *that* — which is a no-op, so every box comes
    // back anchored at x=0. The child is laid out under a tight width instead
    // (the page stretches each line), so it centres the glyphs across the full
    // page. On a line that fills the page the two agree and nothing looks
    // wrong; on a short one — a surah's last line — the boxes sit up to half
    // the slack too far towards the start and the tint slides off the words.
    //
    // `size` is the child's own laid-out size, so pinning minWidth to it
    // reproduces the child's alignment whatever the parent decided, while
    // maxWidth still governs line breaking.
    // `math.max` only guards the layout contract (minWidth must not exceed
    // maxWidth); the child can never be wider than the bound it was given.
    final bound = math.max(maxWidth ?? double.infinity, size.width);
    final tp = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout(minWidth: size.width, maxWidth: bound);

    for (final hl in ranges) {
      if (hl.end <= hl.start) continue;
      final boxes = tp.getBoxesForSelection(
        TextSelection(baseOffset: hl.start, extentOffset: hl.end),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      if (boxes.isEmpty) continue;
      // Union the range's boxes into ONE pill per visual row: a single fill per
      // row avoids the seams translucent overlapping boxes would leave.
      //
      // Rows are grouped by the CENTRE of each box, not by its edges. Spans on
      // one row report different tops and bottoms when they use different fonts
      // — the ayah-number rosette is a separate family from the word glyphs, and
      // `BoxHeightStyle.max` sizes each run to its own metrics — so neither an
      // equal `top` nor plain vertical overlap identifies a row.
      //
      // Overlap in particular is actively wrong, and it is what this replaced: a
      // row carrying a rosette reports a box tall enough to reach into the row
      // below, so a partial first row would merge with the full row under it and
      // `expandToInclude` would stretch the pill across the whole width —
      // painting the tail of the *previous* verse as part of this one.
      //
      // Two boxes on one line share a baseline, so their centres sit within a
      // fraction of a line of each other, while consecutive lines are a whole
      // line apart. Half the shorter box is comfortably inside that gap.
      final ordered = boxes
          .map((b) => Rect.fromLTRB(b.left, b.top, b.right, b.bottom))
          .toList()
        ..sort((a, b) => a.top.compareTo(b.top));
      final rows = <Rect>[];
      // Each row's anchor stays the centre of the FIRST box that opened it, so a
      // taller box joining later cannot drag the row towards its neighbour.
      final rowCentres = <double>[];
      for (final rect in ordered) {
        var merged = false;
        for (var i = 0; i < rows.length; i++) {
          final tolerance = math.min(rect.height, rows[i].height) / 2;
          if ((rect.center.dy - rowCentres[i]).abs() < tolerance) {
            rows[i] = rows[i].expandToInclude(rect);
            merged = true;
            break;
          }
        }
        if (!merged) {
          rows.add(rect);
          rowCentres.add(rect.center.dy);
        }
      }

      final paint = Paint()..color = hl.color;
      for (final row in rows) {
        final rect = Rect.fromLTRB(
          row.left,
          row.top - padTop,
          row.right,
          row.bottom + padBottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.text != text ||
      old.padTop != padTop ||
      old.padBottom != padBottom ||
      old.radius != radius ||
      old.textAlign != textAlign ||
      old.maxWidth != maxWidth ||
      !listEquals(old.ranges, ranges);
}
