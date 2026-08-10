import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';

/// Muted explainer paragraph placed under a [WSettingsGroup] — the long-form
/// counterpart to the one-line row subtitle.
class WSettingsNote extends StatelessWidget {
  const WSettingsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, end: 8.w, top: isTab ? 8 : 10.h),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: isTab ? 11.5 : 9.5.sp,
          color: const Color(0xFF858585),
          height: 1.7,
        ),
      ),
    );
  }
}
