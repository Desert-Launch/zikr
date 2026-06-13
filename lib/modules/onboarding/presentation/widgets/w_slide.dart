import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class SlideData {
  const SlideData({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.gold,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final bool gold;
}

class WSlide extends StatelessWidget {
  const WSlide({super.key, required this.data});
  final SlideData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.gold ? AppColorsLight.accent : AppColorsLight.primary;
    final accentDark =
        data.gold ? const Color(0xFFA8851C) : AppColorsLight.primaryDark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Faint ring encircling the icon, echoing the mockup.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 230.r,
                height: 230.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.10),
                    width: 1.4,
                  ),
                ),
              ),
              Container(
                width: 104.r,
                height: 104.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 48.r),
              ),
            ],
          ),
          SizedBox(height: 36.h),
          Text(
            data.titleKey.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            data.bodyKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.brand.muted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
