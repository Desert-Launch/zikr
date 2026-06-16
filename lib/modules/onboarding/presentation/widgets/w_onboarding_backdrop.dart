import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Soft decorative backdrop shared across the onboarding flow: a couple of
/// faint brand-tinted circles bleeding off the corners. Purely cosmetic and
/// non-interactive, so it sits at the bottom of a [Stack].
class WOnboardingBackdrop extends StatelessWidget {
  const WOnboardingBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          PositionedDirectional(
            top: -70.h,
            end: -60.w,
            child: _circle(230.r, AppColorsLight.primary.withValues(alpha: 0.05)),
          ),

          PositionedDirectional(
            top: 290.h,
            end: 30.w,
            child: _circle(330.r, AppColorsLight.primary.withValues(alpha: 0.05)),
          ),

          PositionedDirectional(
            bottom: -90.h,
            start: -50.w,
            child: _circle(260.r, AppColorsLight.primary.withValues(alpha: 0.03)),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 3),
      shape: BoxShape.circle,
    ),
  );
}
