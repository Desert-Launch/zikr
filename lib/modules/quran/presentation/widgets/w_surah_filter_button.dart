import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';

class WSurahFilterButton extends StatelessWidget {
  const WSurahFilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.green,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color green;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: active ? green : const Color(0xFFF8F8F5),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: active ? green : const Color(0xFFDDE1DD)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: active ? AppTextStyles.white12W400 : AppTextStyles.ink12W400,
          ),
        ),
      ),
    );
  }
}
