import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// A generic icon + title (+ optional subtitle / trailing) settings row used in
/// the prayer settings overview.
class WAdhanSettingRow extends StatelessWidget {
  const WAdhanSettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    // Tablet mirrors WSettingsRow: the 780x844 design height stretches every
    // `.h` by ~1.6x, so an 82.h row floats in ~131px of empty space. Fixed
    // logical values keep the tablet rows as tight as they read on phones.
    final isTab = context.isTablet;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isTab ? 62 : 82.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTab ? 27.w : 18.w, vertical: isTab ? 9 : 12.h),
          child: Row(
            children: [
              WAdhanIconCircle(icon: icon),
              SizedBox(width: isTab ? 18.w : 16.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.ink16W500),
                    if (subtitle != null) ...[
                      SizedBox(height: isTab ? 3 : 3.h),
                      Text(subtitle, style: AppTextStyles.grey12W400),
                    ],
                  ],
                ),
              ),
              WLocalizeRotation(
                child: trailing ?? Icon(Icons.chevron_left_rounded, color: const Color(0xFF777777), size: 22.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
