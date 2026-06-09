import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/s_reminders.dart';
import 'package:quran/modules/reminders/presentation/reminder_styles.dart';
import 'package:quran/modules/reminders/presentation/widgets/w_reminders_header.dart';

class SNReminders extends StatelessWidget {
  const SNReminders({super.key});

  /// Themed popup shown when notifications are disabled, with a shortcut to the
  /// system settings so the user can grant the permission.
  void _showPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        contentPadding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
        actionsPadding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
        title: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_off_rounded,
                  color: AppColorsLight.primary, size: 22.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'reminders_permission_title'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: ctx.brand.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'reminders_permission_denied'.tr(),
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.6,
            color: ctx.brand.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common_cancel'.tr(),
              style: TextStyle(
                color: ctx.brand.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColorsLight.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(
              'reminders_open_settings'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, SReminders state, {String? id}) {
    if (id == null && state.isAtCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reminders_max_reached'.tr())),
      );
      return;
    }
    Modular.to.pushNamed(RemindersRoutes.fullForm(id: id));
  }

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBReminders>();
    return BlocProvider.value(
      value: cb,
      child: Scaffold(
        backgroundColor: context.brand.background,
        body: BlocConsumer<CBReminders, SReminders>(
          listenWhen: (prev, curr) =>
              curr.error == 'reminders_permission_denied' &&
              prev.error != curr.error,
          listener: (context, state) {
            cb.clearError();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) _showPermissionDialog(context);
            });
          },
          builder: (context, state) {
            return Column(
              children: [
                WRemindersHeader(
                  title: 'reminders_title'.tr(),
                  onAdd: () => _openForm(context, state),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      for (final r in state.items) ...[
                        _ReminderTile(reminder: r, cb: cb),
                        SizedBox(height: 12.h),
                      ],
                      _AddCard(onTap: () => _openForm(context, state)),
                      SizedBox(height: 16.h),
                      const _TipCard(),
                    ],
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
    final suffix = reminder.hour >= 12 ? 'reminders_pm'.tr() : 'reminders_am'.tr();
    return '${two(h)}:${two(reminder.minute)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final color = ReminderStyles.colorFor(reminder.colorId);
    return Material(
      color: context.brand.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => Modular.to.pushNamed(
          RemindersRoutes.fullForm(id: reminder.id),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: context.brand.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(ReminderStyles.iconFor(reminder.iconId),
                    color: color, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: context.brand.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatTime(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.brand.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.enabled,
                activeThumbColor: AppColorsLight.primary,
                onChanged: (v) => cb.setEnabled(reminder.id, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppColorsLight.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded,
                  color: AppColorsLight.primary, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'reminders_add_new'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColorsLight.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsLight.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColorsLight.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColorsLight.accent, size: 18.r),
              SizedBox(width: 6.w),
              Text(
                'reminders_tip_title'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: context.brand.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'reminders_tip_body'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              color: context.brand.muted,
            ),
          ),
        ],
      ),
    );
  }
}
