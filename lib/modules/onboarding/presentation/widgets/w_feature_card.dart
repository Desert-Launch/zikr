import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class FeatureData {
  const FeatureData({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

class WFeatureCard extends StatelessWidget {
  const WFeatureCard({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.brand.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(data.icon, color: AppColorsLight.primary, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.titleKey.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  data.bodyKey.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.brand.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
