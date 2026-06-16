import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WCheckCircle extends StatelessWidget {
  const WCheckCircle({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.r,
      height: 30.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColorsLight.primary : Colors.transparent,
        border: Border.all(color: selected ? AppColorsLight.primary : context.brand.border, width: 1.6),
        gradient: selected
            ? LinearGradient(
                colors: [const Color(0xff0D7E5E), const Color(0xff0A6349)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: selected ? Icon(Icons.check_rounded, color: Colors.white, size: 16.r) : null,
    );
  }
}
