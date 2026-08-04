import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';

/// One action button on the full-screen adhan alarm. [filled] marks the primary
/// action (Stop); the outlined variant is the secondary one.
class WAdhanRingingAction extends StatelessWidget {
  const WAdhanRingingAction({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColorsLight.primary : Colors.white;
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(32.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 20.sp),
                SizedBox(width: 8.w),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 17.sp,
                  fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
