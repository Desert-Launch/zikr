import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';

class WOnboardingNextButton extends StatelessWidget {
  const WOnboardingNextButton({
    super.key,
    required this.accent,
    required this.label,
    required this.onTap,
  });
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent == AppColorsLight.accent
                    ? const Color(0xFFA8851C)
                    : AppColorsLight.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
