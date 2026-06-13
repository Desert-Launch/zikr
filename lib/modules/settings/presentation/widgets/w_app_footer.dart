import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class WAppFooter extends StatelessWidget {
  const WAppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 51.r,
          height: 51.r,
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
          child: Icon(
            Icons.star_rounded,
            color: const Color(0xFFD9B947),
            size: 27.r,
          ),
        ),
        SizedBox(height: 11.h),
        Text(
          'home_page_title'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            color: const Color(0xFF777777),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'settings_footer'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 9.sp,
            color: const Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }
}
