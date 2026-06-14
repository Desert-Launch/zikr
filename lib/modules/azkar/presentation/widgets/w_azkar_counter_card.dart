import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
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
    final progress = item.repeat <= 0 ? 0.0 : (completed / item.repeat).clamp(0, 1).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 365.h),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Color(0x25000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(item.textAr, textAlign: TextAlign.center, style: AppTextStyles.ink18W400),
            ),
            SizedBox(height: 28.h),
            Container(
              width: 180.r,
              height: 180.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 8),
                boxShadow: [BoxShadow(color: green.withValues(alpha: 0.08), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$completed', style: AppTextStyles.ink24W700.copyWith(fontSize: 30.sp)),
                  Text('${'azkar_of'.tr()} ${item.repeat}', style: AppTextStyles.ink12W400),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 70.w,
                    child: LinearProgressIndicator(
                      minHeight: 6.h,
                      value: progress,
                      color: green,
                      backgroundColor: const Color(0xFFE7E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            InkWell(
              onTap: onReset,
              child: Container(
                width: 120.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: green.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF8F7F4).withValues(alpha: 0.7),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('azkar_reset_counter'.tr(), style: AppTextStyles.ink14W500),
                    SizedBox(width: 4.w),
                    const Icon(Icons.restart_alt_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
