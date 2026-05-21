import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/theme/app_colors.dart';

class WDetailRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final bool isDark;
  final bool isMultiLine;

  const WDetailRow({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
    required this.isDark,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    final labelColor = isDark ? Colors.white60 : AppColors.cleanTextTertiary;
    final valueColor = isDark ? Colors.white : AppColors.cleanTextPrimary;

    if (isMultiLine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              SizedBox(width: isTab ? 6 : 6.w),
              Text(
                label,
                style: TextStyle(fontSize: 13.spCapped(15), fontWeight: FontWeight.w500, color: labelColor),
              ),
            ],
          ),
          SizedBox(height: isTab ? 6 : 6.h),
          Text(
            value,
            style: TextStyle(fontSize: 14.spCapped(16), fontWeight: FontWeight.w500, color: valueColor, height: 1.5),
          ),
        ],
      );
    }

    return Row(
      children: [
        leading,
        SizedBox(width: isTab ? 10 : 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13.spCapped(15), fontWeight: FontWeight.w500, color: labelColor),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13.spCapped(15), fontWeight: FontWeight.w700, color: valueColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
