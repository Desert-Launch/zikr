import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/presentation/reminder_styles.dart';

class WReminderTile extends StatelessWidget {
  const WReminderTile({required this.reminder, required this.cb, super.key});
  final MReminder reminder;
  final CBReminders cb;

  String _formatTime() {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = reminder.hour > 12 ? reminder.hour - 12 : (reminder.hour == 0 ? 12 : reminder.hour);
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
        onTap: () => Modular.to.pushNamed(RemindersRoutes.fullForm(id: reminder.id)),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: SvgPicture.asset(
                  ReminderStyles.iconAssetFor(reminder.iconId),
                  width: 24.r,
                  height: 24.r,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: context.brand.onSurface),
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
