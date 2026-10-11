import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WOnboardingHeader extends StatelessWidget {
  const WOnboardingHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84.r,
          height: 84.r,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff0D7E5E), Color(0xff0A6349)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: AppColorsLight.primary.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 42.r),
        ),
        SizedBox(height: 26.h),
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 24.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
        ),
      ],
    );
  }
}
