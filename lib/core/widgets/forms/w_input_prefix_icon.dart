import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Leading affix rendered inside a [WSharedField]: an optional required `*`
/// marker, the field icon, and a thin vertical divider that separates the
/// icon from the text — matching the auth design mockups.
class WInputPrefixIcon extends StatelessWidget {
  const WInputPrefixIcon({
    super.key,
    required this.icon,
    this.isRequired = false,
    this.withDivider = true,
  });

  final IconData icon;
  final bool isRequired;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 12.w),
        if (isRequired) ...[
          Text(
            '*',
            style: TextStyle(
              color: AppColorsLight.error,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(width: 6.w),
        ],
        Icon(icon, size: 20.sp, color: brand.muted),
        SizedBox(width: 8.w),
        if (withDivider) Container(width: 1, height: 22.h, color: brand.border),
        SizedBox(width: 10.w),
      ],
    );
  }
}
