import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WReminderTipCard extends StatelessWidget {
  const WReminderTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsLight.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColorsLight.accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: context.brand.accent, shape: BoxShape.circle),
              child: SvgPicture.asset(Assets.icons.bulb.path, width: 18.r, height: 18.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'reminders_tip_title'.tr(),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.brand.onSurface),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'reminders_tip_body'.tr(),
                    style: TextStyle(fontSize: 12.sp, height: 1.6, color: context.brand.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
