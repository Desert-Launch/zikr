import 'package:flutter/material.dart';

/// Two-finger pinch over the Mushaf that changes the Quran text size.
///
/// **Why this drives the size setting instead of transforming the page.** A
/// continuous `Transform.scale` would leave the glyphs resampled rather than
/// re-laid-out, so lines would not re-wrap and the result would not match what
/// the size slider produces. Instead the pinch maps to the SAME text-size value
/// the slider writes, so the two controls are one setting seen two ways.
///
/// **Why raw pointers instead of a [ScaleGestureRecognizer].** The reader sits
/// on a PageView / CustomScrollView whose drag recognizer claims the arena as
/// soon as ONE finger passes touch slop. Fingers rarely land together: if the
/// first one moves before the second arrives, the scroll has already won that
/// pointer's arena, a scale recognizer is rejected for it, and the pinch can
/// never start — the reader pages instead of zooming. A gesture arena decision
/// cannot be taken back, so the pinch is read from a [Listener] instead, which
/// receives every pointer on the hit-test path no matter who won it. Two
/// fingers down therefore ALWAYS mean zoom.
///
/// The scroll views are silenced for the duration through [builder]'s
/// `scrollLocked` flag — swapping in `NeverScrollableScrollPhysics` also
/// cancels the drag that may already be running, and the PageView settles to
/// the nearest page rather than being left stranded between two.
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
    required this.builder,
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
  /// persists the size the pinch settled on. Skipped when the pinch never
  /// actually changed the size (a two-finger tap).
  final ValueChanged<double> onCommit;

  /// Feedback shown while pinching; given the live scale. Omit for none.
  final Widget Function(BuildContext context, double pending)? overlayBuilder;

  /// The content. `scrollLocked` is true from the moment a second finger lands
  /// until the last one lifts — build the scroll views unscrollable while it is
  /// set, or they will fight the pinch.
  final Widget Function(BuildContext context, bool scrollLocked) builder;

  @override
  State<WPinchFontZoom> createState() => _WPinchFontZoomState();
}

/// How far the fingers must spread or close before the size starts moving.
///
/// Without it the tiniest wobble during a two-finger tap would resize the page.
/// Measured on the mean distance from the focal point, so it is roughly half
/// the change in the gap between two fingers.
const double _kSpanSlop = 6;

class _WPinchFontZoomState extends State<WPinchFontZoom> {
  /// Every pointer currently down on the reader, by id — the raw material the
  /// pinch is computed from. Fed by [Listener], so it is complete regardless of
  /// which recognizer won which pointer.
  final Map<int, Offset> _points = <int, Offset>{};

  /// Two or more fingers are down: the scroll views are locked and the badge is
  /// up, whether or not the size has started moving yet.
  bool _pinching = false;

  /// The fingers have moved past [_kSpanSlop], so previews are flowing and a
  /// commit is owed on release.
  bool _resizing = false;

  /// Scale and finger spread at the last anchor point — the pinch is relative
  /// to them, so releasing and pinching again continues from where the last one
  /// landed rather than snapping back.
  double _startScale = 1;
  double _startSpan = 0;

  /// The live scale while the fingers are down; null when not pinching. Only
  /// drives the badge — the page itself is resized through `onPreview`.
  double? _pending;

  /// Mean distance of the fingers from their focal point. Halves the two-finger
  /// gap, which the ratio makes irrelevant, and stays meaningful for three.
  double _span() {
    if (_points.length < 2) return 0;
    var focal = Offset.zero;
    for (final point in _points.values) {
      focal += point;
    }
    focal = focal / _points.length.toDouble();
    var total = 0.0;
    for (final point in _points.values) {
      total += (point - focal).distance;
    }
    return total / _points.length;
  }

  /// Re-bases the pinch on the fingers as they are right now.
  ///
  /// Called at touch-down and again whenever a finger joins or leaves, because
  /// the span jumps when the set of fingers changes and the size must not jump
  /// with it. `_pending` is preferred over `widget.scale` only because the two
  /// are the same value — each preview re-emits it — and reading the local one
  /// keeps the anchor correct even before the parent has rebuilt.
  void _anchor() {
    _startScale = _pending ?? widget.scale;
    _startSpan = _span();
  }

  double _resolve(double factor) =>
      (_startScale * factor).clamp(widget.minScale, widget.maxScale);

  void _onPointerDown(PointerDownEvent event) {
    _points[event.pointer] = event.position;
    if (_points.length < 2) return;
    _anchor();
    // The lock goes on with the second finger, not when the size starts
    // moving: the whole point is to take the gesture back from a page swipe
    // that may already be under way.
    if (!_pinching) {
      setState(() {
        _pinching = true;
        _pending = _startScale;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_points.containsKey(event.pointer)) return;
    _points[event.pointer] = event.position;
    if (!_pinching) return;
    final span = _span();
    if (_startSpan <= 0) {
      _startSpan = span;
      return;
    }
    if (!_resizing) {
      if ((span - _startSpan).abs() < _kSpanSlop) return;
      // Re-anchor on the slop boundary so the first preview starts from a
      // ratio of 1 instead of stepping by the slop the user just spent.
      _resizing = true;
      _anchor();
      return;
    }
    final rounded = (_resolve(span / _startSpan) * 100).roundToDouble() / 100;
    // Whole percent: finer steps cost a full page relayout to move the text by
    // less than the badge can even display.
    if (rounded == _pending) return;
    setState(() => _pending = rounded);
    widget.onPreview(rounded);
  }

  void _onPointerUp(PointerEvent event) {
    if (_points.remove(event.pointer) == null) return;
    // Down to two fingers from three: still a pinch, just a differently
    // spread one.
    if (_points.length >= 2) {
      _anchor();
      return;
    }
    final pending = _pending;
    final resizing = _resizing;
    _resizing = false;
    setState(() {
      _pending = null;
      // The last finger stays lock-bearing: releasing the scroll views while
      // one is still down would hand it a page swipe the user never asked for.
      if (_points.isEmpty) _pinching = false;
    });
    // The one and only write of the gesture, and only if the size actually
    // moved. Not skipped when it equals `widget.scale`: the previews already
    // moved that to the same value, so comparing them would drop every commit.
    if (resizing && pending != null) widget.onCommit(pending);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final overlayBuilder = widget.overlayBuilder;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: Stack(
        children: [
          widget.builder(context, _pinching),
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
