import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_group.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_setting_row.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_verse_card.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';

class SNPrayerSettingsOverview extends StatefulWidget {
  const SNPrayerSettingsOverview({super.key});

  @override
  State<SNPrayerSettingsOverview> createState() => _SNPrayerSettingsOverviewState();
}

class _SNPrayerSettingsOverviewState extends State<SNPrayerSettingsOverview> {
  static const _green = Color(0xFF2F7E63);
  static const _canvas = Color(0xFFFAF9F7);
  static const _gold = Color(0xFFD6A72C);

  /// The fixed سورة فاطر 29 virtue verse shown at the bottom of the screen.
  static const _virtueVerse = EDailyVerse(
    surahNumber: 35,
    surahArabicName: 'فاطر',
    surahName: 'Fatir',
    ayah: 29,
    text:
        'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ وَأَنفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ تِجَارَةً لَّن تَبُورَ',
  );

  bool _automaticLocation = true;

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            WGradientAppBar(title: 'prayer_settings_title'.tr()),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(19.w, 26.h, 19.w, 28.h),
                children: [
                  WAdhanGroup(
                    children: [
                      WAdhanSettingRow(
                        icon: Icons.explore_outlined,
                        title: 'prayer_settings_qibla'.tr(),
                        subtitle: 'prayer_settings_qibla_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(RoutesNames.qiblaBase),
                        trailing: SizedBox(),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  WAdhanGroup(
                    children: [
                      WAdhanSettingRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'prayer_settings_alerts'.tr(),
                        subtitle: 'prayer_settings_alerts_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(AdhanRoutes.notificationsScreen()),
                        trailing: SizedBox(),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 8.h),
                    child: Text('prayer_settings_location_section'.tr(), style: AppTextStyles.grey12W400),
                  ),
                  WAdhanGroup(
                    children: [
                      WAdhanSettingRow(
                        icon: Icons.location_on_outlined,
                        title: 'prayer_settings_auto_location'.tr(),
                        subtitle: 'prayer_settings_auto_location_hint'.tr(),
                        trailing: Transform.scale(
                          scale: .75,
                          child: Switch(
                            value: _automaticLocation,
                            activeTrackColor: _green,
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            onChanged: (value) => setState(() => _automaticLocation = value),
                          ),
                        ),
                      ),
                      WAdhanSettingRow(
                        icon: Icons.location_on_outlined,
                        title: 'prayer_settings_manual_location'.tr(),
                        onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  WHomeVerseCard.staticVerse(gold: _gold, verse: _virtueVerse, label: 'khatma_virtue_title'.tr()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
