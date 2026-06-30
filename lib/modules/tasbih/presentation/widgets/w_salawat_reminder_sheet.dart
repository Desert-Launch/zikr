import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_salawat.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

/// Bottom sheet that configures the salawat-upon-the-Prophet reminder:
/// a master toggle plus a frequency choice (every 1/2/3 hours, or a single
/// specific time). Interval reminders fire 08:30–22:30; the specific time is
/// clamped to that same window.
class WSalawatReminderSheet extends StatelessWidget {
  const WSalawatReminderSheet({required this.cubit, super.key});

  final CBSalawat cubit;

  static const _green = Color(0xFF007A58);

  /// Frequency options. `0` is the "specific time" sentinel.
  static const _intervals = [1, 2, 3, 0];

  /// Opens the sheet for [cubit].
  static Future<void> show(BuildContext context, CBSalawat cubit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => WSalawatReminderSheet(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: BlocBuilder<CBSalawat, STasbih>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            color: _green, size: 22.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text('salawat_reminder_title'.tr(),
                              style: AppTextStyles.ink16W500),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: _green,
                      title: Text('salawat_reminder_enable'.tr(),
                          style: AppTextStyles.ink14W700),
                      subtitle: Text('salawat_reminder_enable_hint'.tr(),
                          style: AppTextStyles.grey12W400),
                      value: state.reminderEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final granted = await Modular.get<NotificationsService>()
                              .requestPermission();
                          if (!granted) return;
                        }
                        await cubit.setReminderEnabled(v);
                      },
                    ),
                    if (state.reminderEnabled) ...[
                      Divider(height: 24.h),
                      Text('salawat_reminder_frequency'.tr(),
                          style: AppTextStyles.ink14W700),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _intervals.map((value) {
                          final selected =
                              state.reminderIntervalHours == value;
                          return ChoiceChip(
                            label: Text(_labelFor(value)),
                            selected: selected,
                            selectedColor: _green,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 13.sp,
                            ),
                            backgroundColor: const Color(0xFFF1F0EC),
                            showCheckmark: false,
                            onSelected: (_) {
                              if (value == 0) {
                                cubit.setReminderTime(
                                    state.reminderHour, state.reminderMinute);
                              } else {
                                cubit.setReminderInterval(value);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12.h),
                      if (state.reminderIsSpecificTime)
                        _TimeRow(state: state, cubit: cubit, green: _green)
                      else
                        _Hint(text: 'salawat_reminder_window_hint'.tr()),
                    ],
                    SizedBox(height: 8.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(int value) {
    switch (value) {
      case 1:
        return 'salawat_reminder_every_1h'.tr();
      case 2:
        return 'salawat_reminder_every_2h'.tr();
      case 3:
        return 'salawat_reminder_every_3h'.tr();
      default:
        return 'salawat_reminder_specific'.tr();
    }
  }
}

/// Row showing the chosen specific time with a button to change it.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.state,
    required this.cubit,
    required this.green,
  });

  final STasbih state;
  final CBSalawat cubit;
  final Color green;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: green,
            side: BorderSide(color: green),
            padding: EdgeInsets.symmetric(vertical: 12.h),
          ),
          icon: Icon(Icons.access_time_rounded, size: 20.sp),
          label: Text(
            '${'salawat_reminder_pick_time'.tr()} — ${time.format(context)}',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked == null) return;
            // Clamp into the 08:00–22:00 window.
            final hour = picked.hour.clamp(8, 22);
            await cubit.setReminderTime(hour, picked.minute);
          },
        ),
        SizedBox(height: 8.h),
        _Hint(text: 'salawat_reminder_specific_hint'.tr()),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12.sp, color: Colors.black54, height: 1.5),
    );
  }
}
