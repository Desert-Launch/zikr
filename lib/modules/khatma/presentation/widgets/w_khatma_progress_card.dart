import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

/// Progress summary card (remaining wirds + progress bar) on the tracker screen.
class WKhatmaProgressCard extends StatelessWidget {
  const WKhatmaProgressCard({super.key, required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF347B60);
    final status = _statusText();
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFDDE6E0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: green.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 7)),
                    ],
                  ),
                  child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 30),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('khatma_current_plan'.tr(), textAlign: TextAlign.end, style: AppTextStyles.ink24W500),
                      SizedBox(height: 2.h),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.grey14W400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 26.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 7.h,
                backgroundColor: const Color(0xFFE7E4DF),
                color: green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final plan = state.plan;
    final total = state.wirds.isNotEmpty ? state.wirds.length : (plan?.totalDays ?? 0);
    if (plan == null || total == 0) {
      return isArabic ? 'انت ملتزم بخطتك' : 'You are on track';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(plan.startedAt.year, plan.startedAt.month, plan.startedAt.day);
    final elapsedDays = today.difference(start).inDays + 1;
    final expectedCompleted = elapsedDays.clamp(0, total).toInt();
    final delta = expectedCompleted - state.completedDays;
    if (delta > 0) {
      return isArabic ? 'انت متأخر عن خطتك ب $delta أيام' : 'You are $delta days behind your plan';
    }
    if (delta < 0) {
      final ahead = delta.abs();
      return isArabic ? 'انت متقدم على خطتك ب $ahead أيام' : 'You are $ahead days ahead of your plan';
    }
    return isArabic ? 'انت ملتزم بخطتك' : 'You are on track';
  }
}
