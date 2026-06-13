import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small muted section header above an adhan settings group.
class WAdhanSectionLabel extends StatelessWidget {
  const WAdhanSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 9.h),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontSize: 10.sp, color: const Color(0xFF777777)),
      ),
    );
  }
}
