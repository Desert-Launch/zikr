import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/s_reminders.dart';
import 'package:quran/modules/reminders/presentation/widgets/w_reminder_add_card.dart';
import 'package:quran/modules/reminders/presentation/widgets/w_reminder_tile.dart';
import 'package:quran/modules/reminders/presentation/widgets/w_reminder_tip_card.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
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
              child: Icon(
                Icons.notifications_off_rounded,
                color: AppColorsLight.primary,
                size: 22.r,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reminders_max_reached'.tr())));
      return;
    }
    Modular.to.pushNamed(RemindersRoutes.fullForm(id: id));
  }

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBReminders>();
    return BlocProvider.value(
      value: cb,
      child: WSharedScaffold(
        backgroundColor: context.brand.background,
        withSafeArea: false,
        padding: EdgeInsets.zero,
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
                        WReminderTile(reminder: r, cb: cb),
                        SizedBox(height: 12.h),
                      ],
                      WReminderAddCard(onTap: () => _openForm(context, state)),
                      SizedBox(height: 16.h),
                      const WReminderTipCard(),
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
