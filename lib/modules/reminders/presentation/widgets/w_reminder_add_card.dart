import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WReminderAddCard extends StatelessWidget {
  const WReminderAddCard({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColorsLight.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'reminders_add_new'.tr(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColorsLight.primary),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.add_rounded, color: AppColorsLight.primary, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
