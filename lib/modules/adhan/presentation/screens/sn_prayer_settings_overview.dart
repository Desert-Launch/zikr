import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_verse_card.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_switch.dart';

/// Prayer-time preferences hub, laid out with the shared settings primitives so
/// it reads as one surface with [SNSettings] — which links here rather than
/// repeating these rows.
class SNPrayerSettingsOverview extends StatefulWidget {
  const SNPrayerSettingsOverview({super.key});

  @override
  State<SNPrayerSettingsOverview> createState() => _SNPrayerSettingsOverviewState();
}

class _SNPrayerSettingsOverviewState extends State<SNPrayerSettingsOverview> {
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
    final isTab = context.isTablet;
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        // Explicit extension — `localize_and_translate` also defines `isRTL`
        // on BuildContext, and importing the app extension makes it ambiguous.
        textDirection: ContextExtensions(context).isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: WGradientAppBar(
                title: 'prayer_settings_title'.tr(),
                subtitle: 'prayer_settings_subtitle'.tr(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(19.w, isTab ? 14 : 18.h, 19.w, isTab ? 20 : 28.h),
              sliver: SliverList.list(
                children: [
                  WSettingsSectionLabel('prayer_settings_general_section'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'prayer_settings_alerts'.tr(),
                        subtitle: 'prayer_settings_alerts_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(AdhanRoutes.notificationsScreen()),
                      ),
                      WSettingsRow(
                        icon: Icons.explore_outlined,
                        title: 'prayer_settings_qibla'.tr(),
                        subtitle: 'prayer_settings_qibla_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(RoutesNames.qiblaBase),
                      ),
                    ],
                  ),
                  SizedBox(height: isTab ? 12 : 15.h),
                  WSettingsSectionLabel('prayer_settings_location_section'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.my_location_rounded,
                        title: 'prayer_settings_auto_location'.tr(),
                        subtitle: 'prayer_settings_auto_location_hint'.tr(),
                        trailing: WSettingsSwitch(
                          value: _automaticLocation,
                          onChanged: (value) => setState(() => _automaticLocation = value),
                        ),
                        onTap: () => setState(() => _automaticLocation = !_automaticLocation),
                      ),
                      WSettingsRow(
                        icon: Icons.location_on_outlined,
                        title: 'prayer_settings_manual_location'.tr(),
                        subtitle: 'prayer_settings_manual_location_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
                      ),
                    ],
                  ),
                  SizedBox(height: isTab ? 28 : 34.h),
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
