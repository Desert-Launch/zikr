import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// The gold-bordered card showing a zekr's virtue (فضل) in the player.
class WAzkarVirtueCard extends StatelessWidget {
  const WAzkarVirtueCard({super.key, required this.text, required this.gold});

  final String text;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 13.r,
            backgroundColor: gold,
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'azkar_virtue'.tr(),
            style: TextStyle(fontSize: 9.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 7.h),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 13.sp, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}
