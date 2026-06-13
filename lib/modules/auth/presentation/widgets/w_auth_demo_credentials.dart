import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Demo credentials hint shown on the login screen when the mock backend is on.
class WAuthDemoCredentials extends StatelessWidget {
  const WAuthDemoCredentials({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsLight.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsLight.accent, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth_demo_creds'.tr(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            'demo@quran.app  ·  P@ssw0rd!',
            style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace'),
          ),
          Text(
            'test@quran.app  ·  Test1234!',
            style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
