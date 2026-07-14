import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 82.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Row(
            children: [
              WAdhanIconCircle(icon: icon),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.ink16W500),
                    if (subtitle != null) ...[SizedBox(height: 3.h), Text(subtitle, style: AppTextStyles.grey12W400)],
                  ],
                ),
              ),
              WLocalizeRotation(
                reverse: true,
                child: trailing ?? Icon(Icons.chevron_left_rounded, color: const Color(0xFF777777), size: 22.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
