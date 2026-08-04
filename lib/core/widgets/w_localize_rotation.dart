import 'package:flutter/material.dart';

/// Horizontally mirrors [child] so directional glyphs (arrows, chevrons,
/// sliders …) point the right way for the current layout direction.
///
/// Flutter does NOT auto-mirror `Icon`s: a back arrow drawn pointing left keeps
/// pointing left in an RTL layout unless it is flipped here.
///
/// The decision comes from the ambient [Directionality] — the same signal that
/// lays the surrounding row out — so an arrow can never disagree with its
/// layout. (It used to key off the *language code*, which falls back to the
/// device locale when the user has not explicitly picked a language; that left
/// every arrow unmirrored on an English-locale phone running the Arabic UI.)
///
/// - Default: mirror in RTL. For glyphs drawn for LTR — e.g.
///   [Icons.arrow_back_rounded], which has to point right in Arabic.
/// - [reverse]: mirror in LTR instead. For glyphs already drawn for Arabic —
///   e.g. [Icons.chevron_left_rounded] used as a "drill in" affordance, which
///   points left in Arabic and has to point right in English.
class WLocalizeRotation extends StatelessWidget {
  const WLocalizeRotation({super.key, required this.child, this.reverse = false});

  final Widget child;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (isRtl == reverse) return child;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: child,
    );
  }
}
