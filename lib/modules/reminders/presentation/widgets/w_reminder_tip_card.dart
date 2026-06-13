import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WReminderTipCard extends StatelessWidget {
  const WReminderTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsLight.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColorsLight.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColorsLight.accent, size: 18.r),
              SizedBox(width: 6.w),
              Text(
                'reminders_tip_title'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: context.brand.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'reminders_tip_body'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              color: context.brand.muted,
            ),
          ),
        ],
      ),
    );
  }
}
