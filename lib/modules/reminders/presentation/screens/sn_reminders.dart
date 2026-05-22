import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/s_reminders.dart';

class SNReminders extends StatelessWidget {
  const SNReminders({super.key});

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBReminders>();
    return BlocProvider.value(
      value: cb,
      child: Scaffold(
        appBar: AppBar(
          title: Text('reminders_title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        ),
        floatingActionButton: BlocBuilder<CBReminders, SReminders>(
          builder: (context, state) {
            return FloatingActionButton.extended(
              backgroundColor: state.isAtCap
                  ? context.brand.muted
                  : AppColorsLight.primary,
              foregroundColor: Colors.white,
              icon: Icon(state.isAtCap
                  ? Icons.do_not_disturb_alt_rounded
                  : Icons.add_rounded),
              label: Text(state.isAtCap
                  ? 'reminders_max_reached'.tr()
                  : 'reminders_add'.tr()),
              onPressed: state.isAtCap
                  ? null
                  : () => Modular.to.pushNamed(RemindersRoutes.fullForm()),
            );
          },
        ),
        body: BlocBuilder<CBReminders, SReminders>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${state.count} / ${CBReminders.cap}',
                          style: TextStyle(
                            color: AppColorsLight.primaryDark,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: state.items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Text(
                              'reminders_empty'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.brand.muted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 80.h),
                          itemCount: state.items.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 8.h),
                          itemBuilder: (_, i) =>
                              _ReminderTile(reminder: state.items[i], cb: cb),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder, required this.cb});
  final MReminder reminder;
  final CBReminders cb;

  String _formatTime() {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = reminder.hour > 12
        ? reminder.hour - 12
        : (reminder.hour == 0 ? 12 : reminder.hour);
    final suffix = reminder.hour >= 12 ? 'م' : 'ص';
    return '${two(h)}:${two(reminder.minute)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: context.brand.border),
      ),
      child: ListTile(
        onTap: () => Modular.to.pushNamed(
          RemindersRoutes.fullForm(id: reminder.id),
        ),
        leading: Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: AppColorsLight.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.notifications_active_outlined,
              color: AppColorsLight.primary, size: 22.r),
        ),
        title: Text(reminder.title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
        subtitle: Text(_formatTime(),
            style: TextStyle(
              fontSize: 12.sp,
              color: context.brand.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        trailing: Switch(
          value: reminder.enabled,
          onChanged: (v) => cb.setEnabled(reminder.id, v),
        ),
      ),
    );
  }
}
