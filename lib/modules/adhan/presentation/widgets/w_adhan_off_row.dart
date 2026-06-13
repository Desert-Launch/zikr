import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// The "off" option in the adhan sound list — disables the prayer's alert.
class WAdhanOffRow extends StatelessWidget {
  const WAdhanOffRow({super.key, required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              const WAdhanIconCircle(icon: Icons.notifications_none_rounded),
              SizedBox(width: 13.w),
              Text(
                'adhan_off'.tr(),
                style: GoogleFonts.cairo(fontSize: 14.sp, color: const Color(0xFF303030)),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_rounded, color: const Color(0xFF42BE88), size: 22.r),
            ],
          ),
        ),
      ),
    );
  }
}
