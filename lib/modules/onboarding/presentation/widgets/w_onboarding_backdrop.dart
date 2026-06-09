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
            top: 120.h,
            start: -90.w,
            child: _circle(180.r, AppColorsLight.accent.withValues(alpha: 0.04)),
          ),
          PositionedDirectional(
            bottom: -90.h,
            start: -50.w,
            child: _circle(260.r, AppColorsLight.primary.withValues(alpha: 0.04)),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
