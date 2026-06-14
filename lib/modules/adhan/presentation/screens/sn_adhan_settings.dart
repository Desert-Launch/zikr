import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
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
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: WGradientAppBar(title: 'adhan_alerts_title'.tr()),
        body: BlocBuilder<CBAdhanSettings, SAdhanSettings>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(27.w, 24.h, 27.w, 28.h),
              children: [
                WAdhanSectionLabel('adhan_prayer_alerts_section'.tr()),
                WAdhanGroup(
                  children: [
                    for (var i = 0; i < _prayers.length; i++)
                      WAdhanPrayerRow(
                        prayerKey: _prayers[i].$1,
                        title: _prayers[i].$2.tr(),
                        state: state,
                        index: i == 0 ? 0 : i - 1,
                        cubit: cubit,
                      ),
                  ],
                ),
                if (defaultTargetPlatform == TargetPlatform.android) ...[
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
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            onChanged: cubit.setAndroidBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (defaultTargetPlatform == TargetPlatform.iOS) ...[
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
                SizedBox(height: 76.h),
                const WAdhanVirtueCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}
