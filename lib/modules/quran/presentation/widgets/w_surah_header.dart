import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Ornate banner shown when a new surah begins on a page.
class WSurahHeader extends StatelessWidget {
  const WSurahHeader({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.paperWarm, AppColors.paperCream],
        ),
        border: Border.all(color: AppColorsLight.primary.withValues(alpha: 0.45), width: 1.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.amiri(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: AppColorsLight.primaryDark,
          ),
        ),
      ),
    );
  }
}
