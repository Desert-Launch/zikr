import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A [ScaleGestureRecognizer] that only ever competes for a TWO-finger gesture.
///
/// The stock recognizer claims the arena as soon as the focal point travels
/// past pan slop — with a single finger down (see `_advanceStateMachine` in
/// `gestures/scale.dart`). Dropped into the Mushaf reader unchanged, that means
/// every horizontal page swipe and every vertical scroll is taken over by the
/// zoom recognizer and the reader stops scrolling at all.
///
/// Suppressing only the ACCEPT decision (never the reject) is what keeps the
/// arena honest: with one finger down this recognizer simply never claims the
/// gesture, so the PageView / CustomScrollView wins it uncontested and later
/// rejects us, which tears down tracking through the normal path. Taps are
/// likewise untouched — a tap never reaches two pointers.
class TwoFingerScaleRecognizer extends ScaleGestureRecognizer {
  TwoFingerScaleRecognizer({super.debugOwner});

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.accepted && pointerCount < 2) return;
    super.resolve(disposition);
  }
}

/// Two-finger pinch over the Mushaf that changes the Quran text size.
///
/// **Why this drives the size setting instead of transforming the page.** A
/// continuous `Transform.scale` would leave the glyphs resampled rather than
/// re-laid-out, so lines would not re-wrap and the result would not match what
/// the size slider produces. Instead the pinch maps to the SAME text-size value
/// the slider writes, so the two controls are one setting seen two ways.
///
/// The page resizes DURING the drag: [onPreview] fires as the fingers move, so
/// the reader reflows under them. Only [onCommit] — once, on release — persists,
/// because a pinch crosses dozens of sizes on the way to the one the user
/// means and none of the intermediate ones are worth a write.
///
/// Updates are quantised to whole percent, which is the resolution the badge
/// can show anyway; sub-percent moves are dropped rather than spending a
/// relayout on a change nobody can see.
class WPinchFontZoom extends StatefulWidget {
  const WPinchFontZoom({
    super.key,
    required this.scale,
    required this.minScale,
    required this.maxScale,
    required this.onPreview,
    required this.onCommit,
    required this.child,
    this.overlayBuilder,
  });

  /// The current text-size scale. Read at gesture start to anchor the pinch;
  /// changes mid-gesture (from [onPreview]) deliberately do not re-anchor it.
  final double scale;
  final double minScale;
  final double maxScale;

  /// Fires as the fingers move, so the page reflows live. Must not persist.
  final ValueChanged<double> onPreview;

  /// Called once per gesture, when the fingers lift — this is the one that
  /// persists the size the pinch settled on.
  final ValueChanged<double> onCommit;

  /// Feedback shown while pinching; given the live scale. Omit for none.
  final Widget Function(BuildContext context, double pending)? overlayBuilder;

  final Widget child;

  @override
  State<WPinchFontZoom> createState() => _WPinchFontZoomState();
}

class _WPinchFontZoomState extends State<WPinchFontZoom> {
  /// Scale at the moment the fingers went down — the pinch is relative to it,
  /// so releasing and pinching again continues from where the last one landed
  /// rather than snapping back.
  double _startScale = 1;

  /// The live scale while the fingers are down; null when not pinching. Only
  /// drives the badge — the page itself is resized through `onPreview`.
  double? _pending;

  double _resolve(double factor) =>
      (_startScale * factor).clamp(widget.minScale, widget.maxScale);

  void _onStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    // Anchored once, at touch-down. `widget.scale` moves under us for the rest
    // of the gesture (each preview re-emits it), so re-reading it later would
    // compound the scale factor against its own output and run away.
    _startScale = widget.scale;
    setState(() => _pending = widget.scale);
  }

  void _onUpdate(ScaleUpdateDetails details) {
    // A two-finger gesture can drop to one finger mid-way; hold the last value
    // rather than resolving against a meaningless scale of 1.
    if (details.pointerCount < 2) return;
    final next = _resolve(details.scale);
    // Whole percent: finer steps cost a full page relayout to move the text by
    // less than the badge can even display.
    final rounded = (next * 100).roundToDouble() / 100;
    if (rounded == _pending) return;
    setState(() => _pending = rounded);
    widget.onPreview(rounded);
  }

  void _onEnd(ScaleEndDetails details) {
    final pending = _pending;
    setState(() => _pending = null);
    // The one and only write of the gesture. Not skipped when it equals
    // `widget.scale`: the previews already moved that to the same value, so
    // comparing them would drop every commit.
    if (pending != null) widget.onCommit(pending);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final overlayBuilder = widget.overlayBuilder;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        TwoFingerScaleRecognizer:
            GestureRecognizerFactoryWithHandlers<TwoFingerScaleRecognizer>(
              () => TwoFingerScaleRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..onStart = _onStart
                ..onUpdate = _onUpdate
                ..onEnd = _onEnd,
            ),
      },
      child: Stack(
        children: [
          widget.child,
          if (pending != null && overlayBuilder != null)
            Positioned.fill(
              child: IgnorePointer(child: overlayBuilder(context, pending)),
            ),
        ],
      ),
    );
  }
}

/// Default pinch feedback: a centred pill with the pending size percentage.
///
/// Pinned LTR — a percentage reads the same in both locales, and mirroring it
/// would put the sign on the wrong side of the number in Arabic.
class WPinchZoomBadge extends StatelessWidget {
  const WPinchZoomBadge({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '${(scale * 100).round()}%',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
