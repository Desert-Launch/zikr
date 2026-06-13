import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

class WTasbihCounterCard extends StatelessWidget {
  const WTasbihCounterCard({
    super.key,
    required this.state,
    required this.totalToday,
    required this.green,
    required this.onTap,
    required this.onReset,
  });

  final STasbih state;
  final int totalToday;
  final Color green;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              state.zekrAr,
              style: GoogleFonts.amiri(
                color: green,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 28.h),
            Container(
              width: 126.r,
              height: 126.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.09),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${state.count}',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '${'tasbih_of'.tr()} ${state.target}',
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 42.w,
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 3.h,
                      color: green,
                      backgroundColor: const Color(0xFFE8E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            Divider(color: green.withValues(alpha: 0.16)),
            SizedBox(height: 6.h),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 14),
                  label: Text('tasbih_reset_counter'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: const BorderSide(color: Color(0xFFE3E2DD)),
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    textStyle: TextStyle(fontSize: 9.sp),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalToday',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'tasbih_today_total'.tr(),
                      style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
