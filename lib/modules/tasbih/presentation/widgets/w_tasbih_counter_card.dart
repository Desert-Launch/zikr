import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
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
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Column(
          children: [
            Text(state.zekrAr, style: AppTextStyles.ink22W700.copyWith(color: Color(0xFF0D7E5E))),
            SizedBox(height: 28.h),
            Container(
              width: 146.r,
              height: 146.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 6),
                boxShadow: [BoxShadow(color: green.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${state.count}', style: AppTextStyles.ink24W500.copyWith(fontSize: 35.sp)),
                  Text(
                    '${'tasbih_of'.tr()} ${state.target}',
                    style: AppTextStyles.grey12W400.copyWith(fontSize: 10.sp),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 60.w,
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 6.h,
                      color: green,
                      backgroundColor: const Color(0xFFE8E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            Divider(indent: 20.w, endIndent: 20.w, color: green.withValues(alpha: 0.16)),
            SizedBox(height: 6.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),

              child: Row(
                children: [
                  InkWell(
                    onTap: onReset,
                    child: Container(
                      width: 120.w,
                      height: 32.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F7F4),
                        border: Border.all(color: green.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [BoxShadow(color: green.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 1)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.black),
                          SizedBox(width: 4.w),
                          Text('tasbih_reset_counter'.tr(), style: AppTextStyles.ink12W500),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(color: Color(0xFFF8F7F4), borderRadius: BorderRadius.circular(50.r)),
                        child: Center(
                          child: Text(
                            '$totalToday',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'tasbih_today_total'.tr(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
