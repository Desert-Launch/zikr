import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class WSettingsRowValue extends StatelessWidget {
  const WSettingsRowValue({
    required this.value,
    required this.showChevron,
    super.key,
  });

  final String? value;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final text = value;
    if (text != null && !showChevron) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E8E5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text.isEmpty ? '1.0.0' : text,
          style: GoogleFonts.cairo(
            fontSize: 9.sp,
            color: const Color(0xFF777777),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showChevron)
          Icon(
            Icons.chevron_left_rounded,
            color: const Color(0xFF6F6F6F),
            size: 21.r,
          ),
        if (text != null) ...[
          SizedBox(width: 7.w),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: const Color(0xFF717171),
            ),
          ),
        ],
      ],
    );
  }
}
