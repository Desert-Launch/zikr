import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_audio_alarms.dart';

/// "Is the alarm actually going to fire?" card.
///
/// Every row here is a real-world reason a scheduled adhan silently never
/// arrives — the failure mode users report as "the app stopped working" when in
/// fact the OS suppressed it. Each maps to a settings page we can deep-link to.
/// The card hides itself entirely when everything is granted.
class WAdhanAlarmReadiness extends StatelessWidget {
  const WAdhanAlarmReadiness({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBAdhanSettings, SAdhanSettings, SAdhanSettings>(
      selector: (s) => s,
      builder: (context, state) {
        final perms = state.alarmPermissions;
        if (state.loading || perms.allGranted) return const SizedBox.shrink();

        final cubit = context.read<CBAdhanSettings>();
        final issues = <Widget>[
          if (!perms.canScheduleExact)
            _ReadinessRow(
              title: 'adhan_alarm_issue_exact'.tr(),
              action: 'adhan_alarm_fix'.tr(),
              onTap: () => cubit.openAlarmSetting(AdhanOsSetting.exactAlarm),
            ),
          if (!perms.canUseFullScreenIntent)
            _ReadinessRow(
              title: 'adhan_alarm_issue_fullscreen'.tr(),
              action: 'adhan_alarm_fix'.tr(),
              onTap: () =>
                  cubit.openAlarmSetting(AdhanOsSetting.fullScreenIntent),
            ),
          if (!perms.canDrawOverlays)
            _ReadinessRow(
              title: 'adhan_alarm_issue_overlay'.tr(),
              action: 'adhan_alarm_fix'.tr(),
              onTap: () => cubit.openAlarmSetting(AdhanOsSetting.overlay),
            ),
          if (perms.isBatteryOptimized)
            _ReadinessRow(
              title: 'adhan_alarm_issue_battery'.tr(),
              action: 'adhan_alarm_fix'.tr(),
              onTap: () =>
                  cubit.openAlarmSetting(AdhanOsSetting.batteryOptimization),
            ),
          if (perms.hasOemAutostartManager)
            _ReadinessRow(
              title: 'adhan_alarm_issue_autostart'.tr().replaceFirst(
                '{{oem}}',
                _oemLabel(state.manufacturer),
              ),
              action: 'adhan_alarm_fix'.tr(),
              onTap: () => cubit.openAlarmSetting(AdhanOsSetting.oemAutostart),
            ),
        ];
        if (issues.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColorsLight.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppColorsLight.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColorsLight.accent,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'adhan_alarm_readiness_title'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColorsLight.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'adhan_alarm_readiness_body'.tr(),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: AppColorsLight.muted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 10.h),
              ...issues,
            ],
          ),
        );
      },
    );
  }

  /// Friendly OEM name for the autostart guidance. Falls back to the raw
  /// manufacturer string, which is still more useful than a generic label.
  String _oemLabel(String manufacturer) => switch (manufacturer) {
    'xiaomi' || 'redmi' || 'poco' => 'Xiaomi',
    'oppo' => 'OPPO',
    'realme' => 'realme',
    'vivo' => 'vivo',
    'huawei' || 'honor' => 'Huawei',
    'samsung' => 'Samsung',
    'oneplus' => 'OnePlus',
    '' => 'OEM',
    _ => manufacturer,
  };
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColorsLight.onSurface,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColorsLight.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
