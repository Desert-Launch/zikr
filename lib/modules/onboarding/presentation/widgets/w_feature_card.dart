import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class FeatureData {
  const FeatureData({required this.icon, required this.titleKey, required this.bodyKey});
  final String icon;
  final String titleKey;
  final String bodyKey;
}

class WFeatureCard extends StatelessWidget {
  const WFeatureCard({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.h,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.titleKey.tr(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2.h),
              Text(
                data.bodyKey.tr(),
                style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
              ),
            ],
          ),
          SizedBox(width: 14.w),

          Container(
            width: 48.r,
            height: 48.r,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: SvgPicture.asset(data.icon, colorFilter: ColorFilter.mode(AppColorsLight.primary, BlendMode.srcIn)),
          ),
        ],
      ),
    );
  }
}
