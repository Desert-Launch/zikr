import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Label/value statistics row on the khatma completed screen.
class WKhatmaStatRow extends StatelessWidget {
  const WKhatmaStatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted)),
        ),
        Text(value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColorsLight.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}
