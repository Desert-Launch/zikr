import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

/// The large tap-to-count card in the player: the zekr text, a circular counter
/// with progress, and a reset action.
class WAzkarCounterCard extends StatelessWidget {
  const WAzkarCounterCard({
    super.key,
    required this.item,
    required this.completed,
    required this.green,
    required this.onTap,
    required this.onReset,
  });

  final MAzkarItem item;
  final int completed;
  final Color green;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = item.repeat <= 0
        ? 0.0
        : (completed / item.repeat).clamp(0, 1).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 365.h),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                item.textAr,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 20.sp, height: 1.8),
              ),
            ),
            SizedBox(height: 28.h),
            Container(
              width: 128.r,
              height: 128.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$completed',
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '${'azkar_of'.tr()} ${item.repeat}',
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 42.w,
                    child: LinearProgressIndicator(
                      minHeight: 3.h,
                      value: progress,
                      color: green,
                      backgroundColor: const Color(0xFFE7E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 14),
              label: Text('azkar_reset_counter'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                textStyle: TextStyle(fontSize: 9.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
