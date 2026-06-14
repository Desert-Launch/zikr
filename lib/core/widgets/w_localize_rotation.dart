import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Horizontally mirrors [child] based on the active language so directional
/// widgets (arrows, chevrons, sliders …) point the right way in each locale.
///
/// By default the child is shown as-is in Arabic and flipped in English.
/// Pass [reverse] to invert that mapping (flipped in Arabic, as-is in English).
class WLocalizeRotation extends StatelessWidget {
  const WLocalizeRotation({super.key, required this.child, this.reverse = false});

  final Widget child;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    final flip = isArabic == reverse;

    if (!flip) return child;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
      child: child,
    );
  }
}
