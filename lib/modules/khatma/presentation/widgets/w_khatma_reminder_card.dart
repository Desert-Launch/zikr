import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
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
    const green = Color(0xFF007A58);
    final plan = state.plan;
    if (plan == null) return const SizedBox.shrink();
    final time = TimeOfDay(
      hour: plan.reminderHour,
      minute: plan.reminderMinute,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDDE6E0)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: plan.reminderEnabled,
            activeTrackColor: green,
            title: Text(
              'khatma_daily_wird'.tr(),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              time.format(context),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            onChanged: cubit.setReminderEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.access_time_rounded,
              color: green,
            ),
            title: Text(
              'khatma_reminder_time'.tr(),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              time.format(context),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                await cubit.setReminderTime(picked.hour, picked.minute);
              }
            },
          ),
        ],
      ),
    );
  }
}
