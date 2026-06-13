import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

/// Progress summary card (remaining wirds + progress bar) on the tracker screen.
class WKhatmaProgressCard extends StatelessWidget {
  const WKhatmaProgressCard({super.key, required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF007A58);
    final remaining = state.wirds.length - state.completedDays;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDDE6E0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'khatma_current_plan'.tr(),
                    style: TextStyle(fontSize: 17.sp),
                  ),
                  Text(
                    'khatma_remaining_wirds'.tr().replaceFirst(
                      '{{n}}',
                      '$remaining',
                    ),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFE8E2BF),
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}
