import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class WTasbihVirtueCard extends StatelessWidget {
  const WTasbihVirtueCard({super.key, required this.gold});

  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -35.h,
            end: -30.w,
            child: Container(
              width: 82.r,
              height: 82.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gold.withValues(alpha: 0.15),
                  width: 3,
                ),
              ),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: 13.r,
                backgroundColor: gold,
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'tasbih_virtue_title'.tr(),
                style: TextStyle(fontSize: 8.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 7.h),
              Text(
                'tasbih_virtue_body'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 12.sp, height: 1.7),
              ),
              SizedBox(height: 5.h),
              Text(
                'tasbih_virtue_source'.tr(),
                style: TextStyle(fontSize: 7.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
