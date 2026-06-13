import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Header for the "other azkar" category browser, showing the total number of
/// categories.
class WAzkarOtherHeader extends StatelessWidget {
  const WAzkarOtherHeader({
    super.key,
    required this.green,
    required this.categoryCount,
    required this.onBack,
  });

  final Color green;
  final int categoryCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 21.r,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              child: const Text('🤲', style: TextStyle(fontSize: 20)),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'azkar_other_title'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$categoryCount ${'azkar_categories'.tr()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
