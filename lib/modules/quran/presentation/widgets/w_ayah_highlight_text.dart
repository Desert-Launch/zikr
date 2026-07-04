import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A highlighted character range inside a laid-out span tree, with its fill.
@immutable
class AyahHighlight {
  const AyahHighlight({required this.start, required this.end, required this.color});

  /// Inclusive start / exclusive end offsets into the concatenated plain text
  /// of the span tree (WidgetSpans count as one character).
  final int start;
  final int end;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is AyahHighlight && other.start == start && other.end == end && other.color == color;

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
    final child = RichText(textAlign: textAlign, textDirection: TextDirection.rtl, text: text);
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
      // Each highlighted range lives on a single visual line (exact mode renders
      // one line per widget), so union its boxes into one pill — a single fill
      // avoids seams where translucent boxes would otherwise overlap.
      var rect = Rect.fromLTRB(boxes.first.left, boxes.first.top, boxes.first.right, boxes.first.bottom);
      for (final b in boxes.skip(1)) {
        rect = rect.expandToInclude(Rect.fromLTRB(b.left, b.top, b.right, b.bottom));
      }
      rect = Rect.fromLTRB(rect.left, rect.top - pad, rect.right, rect.bottom + pad);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..color = hl.color);
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
