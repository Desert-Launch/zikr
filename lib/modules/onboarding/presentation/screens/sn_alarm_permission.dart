import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_alarm_permission_switch.dart';
import 'package:quran/modules/adhan/services/adhan_audio_alarms.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';

/// Android-only onboarding step: the two grants that decide whether the adhan
/// can take over the screen at prayer time.
///
/// Neither has a runtime prompt — both live on a settings page — so each row
/// deep-links there and reflects the live grant when the user comes back
/// ([WAlarmPermissionRefresher] re-reads them on resume). Skippable: the adhan
/// still fires as a notification without them, and the same switches stay
/// available in Settings and in the adhan screen.
class SNAlarmPermission extends StatelessWidget {
  const SNAlarmPermission({super.key});

  Future<void> _finish(BuildContext context) async {
    await Modular.get<CBOnboarding>().markComplete();
    if (!context.mounted) return;
    Modular.to.navigate(RoutesNames.homeBase);
  }

  @override
  Widget build(BuildContext context) {
    return WAlarmPermissionRefresher(
      child: Scaffold(
        body: Stack(
          children: [
            const WOnboardingBackdrop(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 36.h),
                    Container(
                      width: 96.r,
                      height: 96.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0D7E5E), Color(0xff0A6349)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsLight.primary.withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 46.r,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'onboarding_alarm_title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: 300.w,
                      child: Text(
                        'onboarding_alarm_body'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.brand.muted,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    const _PermissionCards(),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _finish(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColorsLight.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'onboarding_alarm_continue'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'onboarding_alarm_note'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.brand.muted,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two grant cards. Rebuilt on every permission refresh so a grant made in
/// system settings ticks over as soon as the user returns.
class _PermissionCards extends StatelessWidget {
  const _PermissionCards();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBAdhanSettings, SAdhanSettings, AdhanAlarmPermissions>(
      selector: (s) => s.alarmPermissions,
      builder: (context, perms) {
        // Modular.get, not context.read — this file imports flutter_modular for
        // navigation, and its BuildContext extension collides with bloc's.
        final cubit = Modular.get<CBAdhanSettings>();
        return Column(
          children: [
            for (final info in alarmPermissionInfos(perms))
              _PermissionCard(
                info: info,
                onTap: () => cubit.openAlarmSetting(info.setting),
              ),
          ],
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.info, required this.onTap});

  final AlarmPermissionInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              info.icon,
              size: 24.r,
              color: AppColorsLight.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.titleKey.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  info.subtitleKey.tr(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.brand.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          WAlarmPermissionSwitch(granted: info.granted, onTap: onTap),
        ],
      ),
    );
  }
}
