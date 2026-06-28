import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_before_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_group.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_prayer_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_section_label.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_setting_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_virtue_card.dart';

class SNAdhanSettings extends StatelessWidget {
  const SNAdhanSettings({super.key});

  static const _canvas = Color(0xFFFAF9F7);
  static const _green = Color(0xFF2F7E63);
  static const _prayers = [
    ('fajr', 'prayer_fajr'),
    ('sunrise', 'prayer_sunrise'),
    ('dhuhr', 'prayer_dhuhr'),
    ('asr', 'prayer_asr'),
    ('maghrib', 'prayer_maghrib'),
    ('isha', 'prayer_isha'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBAdhanSettings>();
    return BlocProvider.value(
      value: cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Directionality(
          textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            children: [
              WGradientAppBar(title: 'adhan_alerts_title'.tr()),
              Expanded(
                child: BlocBuilder<CBAdhanSettings, SAdhanSettings>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      padding: EdgeInsets.fromLTRB(27.w, 24.h, 27.w, 28.h),
                      children: [
                        if (!state.hasPermission) ...[
                          _PermissionWarning(onFix: cubit.requestPermission),
                          SizedBox(height: 18.h),
                        ],
                        if (state.needsDefaultDownload) ...[
                          _DefaultDownloadPrompt(busy: state.retryingDownload, onRetry: cubit.retryDefaultDownload),
                          SizedBox(height: 18.h),
                        ],
                        WAdhanSectionLabel('adhan_prayer_alerts_section'.tr()),
                        WAdhanGroup(
                          children: [
                            for (var i = 0; i < _prayers.length; i++)
                              WAdhanPrayerRow(
                                prayerKey: _prayers[i].$1,
                                title: _prayers[i].$2.tr(),
                                state: state,
                                cubit: cubit,
                              ),
                          ],
                        ),

                        if (defaultTargetPlatform ==
                            TargetPlatform.android) ...[
                          SizedBox(height: 18.h),
                          WAdhanSectionLabel('adhan_playback_section'.tr()),
                          WAdhanGroup(
                            children: [
                              WAdhanSettingRow(
                                icon: Icons.volume_up_outlined,
                                title: 'adhan_background_full'.tr(),
                                subtitle: 'adhan_background_full_hint'.tr(),
                                trailing: Transform.scale(
                                  scale: .75,
                                  child: Switch(
                                    value: state.androidBackgroundFullAdhan,
                                    activeTrackColor: _green,
                                    thumbColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                    onChanged: cubit.setAndroidBackground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Aggressive OEM battery managers can delay/kill the
                          // exact alarm that fires the full adhan — surface the
                          // exemption prompt only once the feature is on.
                          if (state.androidBackgroundFullAdhan &&
                              state.showBatteryNote) ...[
                            SizedBox(height: 12.h),
                            _BatteryGuidanceNote(
                              onAllow: cubit.requestBatteryExemption,
                            ),
                          ],
                        ] else if (defaultTargetPlatform ==
                            TargetPlatform.iOS) ...[
                          SizedBox(height: 18.h),
                          WAdhanSectionLabel('adhan_playback_section'.tr()),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18.r,
                                  color: const Color(0xFF858585),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    'adhan_ios_full_note'.tr(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.sp,
                                      height: 1.5,
                                      color: const Color(0xFF858585),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        const WAdhanVirtueCard(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amber prompt shown when the selected default voice still needs downloading
/// (e.g. the first-launch fetch failed offline). Tapping retries.
class _DefaultDownloadPrompt extends StatelessWidget {
  const _DefaultDownloadPrompt({required this.busy, required this.onRetry});

  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onRetry,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF0D9B5)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_download_outlined, size: 20.r, color: const Color(0xFFD79A3B)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'adhan_default_download_title'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8A6D3B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'adhan_default_download_hint'.tr(),
                    style: GoogleFonts.cairo(fontSize: 9.sp, color: const Color(0xFFA98B5B)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            if (busy)
              SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(strokeWidth: 2.r, color: const Color(0xFFD79A3B)),
              )
            else
              Text(
                'adhan_download'.tr(),
                style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFFC8841F)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Red warning shown when notification permission is denied — nothing fires
/// without it. Tapping "Enable" re-requests the OS permission.
class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning({required this.onFix});

  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onFix,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEDED),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF0CECE)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, size: 20.r, color: const Color(0xFFC0473F)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'adhan_permission_denied'.tr(),
                style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF8E3A34)),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'adhan_permission_fix'.tr(),
              style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFFC0473F)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Android-only guidance: aggressive OEM battery managers can delay or kill
/// exact alarms. Tapping "Allow" requests the battery-optimization exemption.
class _BatteryGuidanceNote extends StatelessWidget {
  const _BatteryGuidanceNote({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFD8E4DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.battery_alert_outlined, size: 18.r, color: const Color(0xFF2F7E63)),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'adhan_battery_note_title'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF303030),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'adhan_battery_note_hint'.tr(),
                      style: GoogleFonts.cairo(fontSize: 10.sp, height: 1.5, color: const Color(0xFF6F8079)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onAllow,
              child: Text(
                'adhan_battery_note_action'.tr(),
                style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2F7E63)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
