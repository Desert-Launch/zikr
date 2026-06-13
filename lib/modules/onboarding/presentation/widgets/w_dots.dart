import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WDots extends StatelessWidget {
  const WDots({
    super.key,
    required this.count,
    required this.index,
    required this.color,
  });
  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: i == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: i == index ? color : context.brand.border,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }
}
