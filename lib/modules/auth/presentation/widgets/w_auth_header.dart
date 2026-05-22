import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Top-of-screen header used across auth screens. Renders a thin green
/// gradient band with the app icon + title + optional subtitle.
class WAuthHeader extends StatelessWidget {
  const WAuthHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 36.h, 20.w, 28.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: AppColorsLight.accent, size: 26.r),
              ),
              SizedBox(width: 12.w),
              Text(
                'القرآن الكريم',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 6.h),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 13.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
