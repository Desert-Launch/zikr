import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';

class WSettingsSectionLabel extends StatelessWidget {
  const WSettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, bottom: context.isTablet ? 6 : 7.h),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: context.isTablet ? 12 : 10.sp,
          color: const Color(0xFF777777),
          height: 1,
        ),
      ),
    );
  }
}
