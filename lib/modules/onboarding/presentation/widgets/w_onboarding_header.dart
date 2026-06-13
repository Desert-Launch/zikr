import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WOnboardingHeader extends StatelessWidget {
  const WOnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84.r,
          height: 84.r,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: AppColorsLight.primary.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(Icons.language_rounded, color: Colors.white, size: 42.r),
        ),
        SizedBox(height: 16.h),
        Text(
          'onboarding_language_title'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'onboarding_language_subtitle'.tr(),
          style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
        ),
      ],
    );
  }
}
