import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';

class WStarNumber extends StatelessWidget {
  const WStarNumber({super.key, required this.number, required this.green});

  final int number;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42.r,
      height: 42.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: green.withValues(alpha: 0.18), size: 42.r),
          Text('$number', style: AppTextStyles.ink12W700.copyWith(color: green, height: 1.2)),
        ],
      ),
    );
  }
}
