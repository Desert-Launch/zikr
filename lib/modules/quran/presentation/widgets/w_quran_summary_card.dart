import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quran/core/theme/app_text_styles.dart';

class WQuranSummaryCard extends StatelessWidget {
  const WQuranSummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              SvgPicture.asset(icon, colorFilter: ColorFilter.mode(color, BlendMode.srcIn), width: 19.r, height: 19.r),
              SizedBox(height: 12.h),
              Text(value, style: AppTextStyles.ink14W700.copyWith(color: color)),
              SizedBox(height: 5.h),
              Text(label, style: AppTextStyles.ink12W400.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
