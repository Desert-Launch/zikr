import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WCircleButton extends StatelessWidget {
  const WCircleButton({super.key, required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.brand.surface,
            border: Border.all(color: context.brand.border),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: context.brand.muted,
            size: 22.r,
          ),
        ),
      ),
    );
  }
}
