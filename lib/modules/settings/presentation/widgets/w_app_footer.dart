import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';

class WAppFooter extends StatelessWidget {
  const WAppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return Column(
      children: [
        Container(
          width: 51.r,
          height: 51.r,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF2F7E63),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
        ),
        SizedBox(height: isTab ? 9 : 11.h),
        Text(
          'home_page_title'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isTab ? 14.5 : 12.sp,
            color: const Color(0xFF777777),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'settings_footer'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: isTab ? 11.5 : 9.sp,
            color: const Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }
}
