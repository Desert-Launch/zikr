import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

class WBasmalaLine extends StatelessWidget {
  const WBasmalaLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          style: GoogleFonts.amiri(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.brandPurpleDark,
          ),
        ),
      ),
    );
  }
}
