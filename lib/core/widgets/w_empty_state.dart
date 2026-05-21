import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/theme/app_colors.dart';

class WEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const WEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64.spCapped(72), color: isDark ? Colors.white24 : AppColors.neutralBorderMedium),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.spCapped(17),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : AppColors.cleanTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13.spCapped(15),
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white24 : AppColors.cleanTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
