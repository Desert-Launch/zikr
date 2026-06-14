import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';

class WTasbihVirtueCard extends StatelessWidget {
  const WTasbihVirtueCard({super.key, required this.gold});

  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: -35.h,
            end: -30.w,
            child: Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold.withValues(alpha: 0.15), width: 3),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15.r),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: gold,
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 20.sp),
                ),
                SizedBox(height: 5.h),
                Text('tasbih_virtue_title'.tr(), style: AppTextStyles.grey12W400),
                SizedBox(height: 7.h),
                Text('tasbih_virtue_body'.tr(), textAlign: TextAlign.center, style: AppTextStyles.ink16W400),
                SizedBox(height: 5.h),
                Text('tasbih_virtue_source'.tr(), style: AppTextStyles.grey12W400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
