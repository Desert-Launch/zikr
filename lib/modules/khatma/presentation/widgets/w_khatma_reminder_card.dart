import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

/// Reminder enable/time card on the tracker screen.
class WKhatmaReminderCard extends StatelessWidget {
  const WKhatmaReminderCard({
    super.key,
    required this.cubit,
    required this.state,
  });

  final CBKhatma cubit;
  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF347B60);
    final plan = state.plan;
    if (plan == null) return const SizedBox.shrink();
    final time = TimeOfDay(
      hour: plan.reminderHour,
      minute: plan.reminderMinute,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => _pickTime(context, cubit, time),
      child: Container(
        height: 98.h,
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 22.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFDDE6E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.88,
              child: Switch.adaptive(
                value: plan.reminderEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE6E6E6),
                onChanged: cubit.setReminderEnabled,
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'khatma_daily_wird'.tr(),
                  textAlign: TextAlign.end,
                  style: AppTextStyles.ink20W400,
                ),
                SizedBox(height: 2.h),
                Text(
                  time.format(context),
                  textAlign: TextAlign.end,
                  style: AppTextStyles.grey16W400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    CBKhatma cubit,
    TimeOfDay time,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked == null) return;
    await cubit.setReminderTime(picked.hour, picked.minute);
  }
}
