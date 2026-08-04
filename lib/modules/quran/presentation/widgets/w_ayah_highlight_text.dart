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
/// BEHIND the given [ranges], grown vertically by [pad] on each side.
///
/// The whole point: the highlight can read taller than the glyphs without
/// touching the text's line-height, so line spacing stays tight. The pill is
/// measured by re-laying-out an identical [TextPainter] under the same
/// constraints as the child, so its boxes line up exactly with the rendered
/// text. Taps still land on the child's span recognizers (the painter draws
/// behind and never intercepts hits).
class WAyahHighlightText extends StatelessWidget {
  const WAyahHighlightText({
    required this.text,
    required this.ranges,
    required this.pad,
    this.textAlign = TextAlign.start,
    this.maxWidth,
    this.radius = 8,
    super.key,
  });

  final TextSpan text;
  final List<AyahHighlight> ranges;

  /// Vertical inflation (logical px) added above AND below each highlight box.
  final double pad;
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
        pad: pad,
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
    required this.pad,
    required this.radius,
    required this.textAlign,
    required this.maxWidth,
  });

  final TextSpan text;
  final List<AyahHighlight> ranges;
  final double pad;
  final double radius;
  final TextAlign textAlign;
  final double? maxWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Mirror the child RichText exactly: same spans, direction, align, and the
    // RichText default (no text scaling), so measured boxes match the glyphs.
    final tp = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: maxWidth ?? double.infinity);

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
      // Rows are grouped by VERTICAL OVERLAP, not by an equal `top`. Spans on
      // one row can report different tops when they use different fonts — the
      // ayah-number glyphs are a separate family from the word glyphs — and
      // keying on `top` split a single highlight into two rects of different
      // heights. Genuinely wrapped rows don't overlap, so they still get their
      // own pill instead of one block bridging the gap between them.
      final ordered = boxes
          .map((b) => Rect.fromLTRB(b.left, b.top, b.right, b.bottom))
          .toList()
        ..sort((a, b) => a.top.compareTo(b.top));
      final rows = <Rect>[];
      for (final rect in ordered) {
        if (rows.isNotEmpty && rect.top < rows.last.bottom) {
          rows[rows.length - 1] = rows.last.expandToInclude(rect);
        } else {
          rows.add(rect);
        }
      }

      final paint = Paint()..color = hl.color;
      for (final row in rows) {
        final rect = Rect.fromLTRB(
          row.left,
          row.top - pad,
          row.right,
          row.bottom + pad,
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
      old.pad != pad ||
      old.radius != radius ||
      old.textAlign != textAlign ||
      old.maxWidth != maxWidth ||
      !listEquals(old.ranges, ranges);
}
