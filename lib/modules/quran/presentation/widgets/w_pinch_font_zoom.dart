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
/// **Why this drives the size setting instead of transforming the page.** The
/// reader preloads the per-page glyph fonts in a ±2-page window and caches page
/// layout ±3 with eviction. A continuous `Transform.scale` would force every
/// cached page to relayout on every frame of the pinch, which is exactly the
/// work that windowing exists to avoid. So the pinch maps to the SAME text-size
/// value the settings slider writes, and the page is relaid out once, when the
/// fingers lift.
///
/// While the pinch is live only [overlayBuilder] rebuilds — a small badge
/// showing where the size will land. The page itself does not resize until
/// [onCommit], so there is one relayout per gesture rather than one per frame.
class WPinchFontZoom extends StatefulWidget {
  const WPinchFontZoom({
    super.key,
    required this.scale,
    required this.minScale,
    required this.maxScale,
    required this.onCommit,
    required this.child,
    this.overlayBuilder,
  });

  /// The persisted text-size scale the pinch starts from.
  final double scale;
  final double minScale;
  final double maxScale;

  /// Called once per gesture, when the fingers lift — never mid-pinch.
  final ValueChanged<double> onCommit;

  /// Feedback shown while pinching; given the pending scale. Omit for none.
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

  /// Where the size will land when the fingers lift; null when not pinching.
  double? _pending;

  double _resolve(double factor) =>
      (_startScale * factor).clamp(widget.minScale, widget.maxScale);

  void _onStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _startScale = widget.scale;
    setState(() => _pending = widget.scale);
  }

  void _onUpdate(ScaleUpdateDetails details) {
    // A two-finger gesture can drop to one finger mid-way; keep the last
    // pending value rather than resolving against a meaningless scale of 1.
    if (details.pointerCount < 2) return;
    final next = _resolve(details.scale);
    // Rounded to whole percent: the size is rendered as a percentage, and
    // rebuilding the badge for changes it cannot show is wasted work.
    final rounded = (next * 100).roundToDouble() / 100;
    if (rounded == _pending) return;
    setState(() => _pending = rounded);
  }

  void _onEnd(ScaleEndDetails details) {
    final pending = _pending;
    setState(() => _pending = null);
    // The one and only write, and therefore the one and only relayout.
    if (pending != null && pending != widget.scale) widget.onCommit(pending);
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
