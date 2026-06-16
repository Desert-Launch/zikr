import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';

class SlideData {
  const SlideData({required this.icon, required this.titleKey, required this.bodyKey, required this.gold});
  final String icon;
  final String titleKey;
  final String bodyKey;
  final bool gold;
}

class WSlide extends StatelessWidget {
  const WSlide({super.key, required this.data});
  final SlideData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.gold ? Color(0xffD4AF37) : Color(0xff0D7E5E);
    final accentDark = data.gold ? const Color(0xFFB8941F) : Color(0xff0A6349);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Faint ring encircling the icon, echoing the mockup.
          Stack(
            alignment: Alignment.center,
            children: [
              // Container(
              //   width: 230.r,
              //   height: 230.r,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     border: Border.all(color: accent.withValues(alpha: 0.10), width: 1.4),
              //   ),
              // ),
              SizedBox(height: 100.h),
              Container(
                width: 104.r,
                height: 104.r,
                margin: EdgeInsets.only(top: 65.h),
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 14)),
                  ],
                ),
                child: SvgPicture.asset(data.icon),
              ),
            ],
          ),
          SizedBox(height: 76.h),
          Text(
            data.titleKey.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 26.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: 290.w,
            child: Text(
              data.bodyKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: context.brand.muted, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}
