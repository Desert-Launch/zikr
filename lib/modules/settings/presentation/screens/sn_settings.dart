import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_alarm_permission_switch.dart';
import 'package:quran/modules/adhan/services/adhan_audio_alarms.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_preferred_reader_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_app_footer.dart';
import 'package:quran/modules/settings/presentation/widgets/w_profile_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_switch.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_salawat.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_salawat_reminder_sheet.dart';

/// The app's settings hub.
///
/// Grouped by feature, and every feature row is a *reference* — it pushes the
/// screen (or opens the sheet) that already owns those controls. Nothing here
/// duplicates a toggle that lives elsewhere, so there is only ever one place a
/// given preference can be changed.
class SNSettings extends StatefulWidget {
  const SNSettings({super.key});

  @override
  State<SNSettings> createState() => _SNSettingsState();
}

class _SNSettingsState extends State<SNSettings> {
  static const _canvas = Color(0xFFFAF9F7);
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    final gap = SizedBox(height: isTab ? 12 : 15.h);
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
              child: WGradientAppBar(title: 'settings_title'.tr(), subtitle: 'settings_subtitle'.tr()),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(19.w, isTab ? 14 : 18.h, 19.w, isTab ? 20 : 24.h),
              sliver: SliverList.list(
                children: [
                  const WProfileCard(),
                  gap,
                  WSettingsSectionLabel('settings_general'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.language_rounded,
                        title: 'settings_language'.tr(),
                        subtitle: 'settings_language_hint'.tr(),
                        value: LocalizeAndTranslate.getLanguageCode() == 'ar' ? 'العربية' : 'English',
                        onTap: _showLanguagePicker,
                      ),
                      WSettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'settings_notifications'.tr(),
                        subtitle: 'settings_notifications_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(RoutesNames.remindersBase),
                      ),
                    ],
                  ),
                  gap,
                  WSettingsSectionLabel('settings_adhan_section'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.access_time_rounded,
                        title: 'prayer_settings_title'.tr(),
                        subtitle: 'prayer_settings_subtitle'.tr(),
                        onTap: () => Modular.to.pushNamed(AdhanRoutes.overview()),
                      ),
                      WSettingsRow(
                        icon: Icons.volume_up_outlined,
                        title: 'settings_adhan'.tr(),
                        subtitle: 'settings_adhan_hint'.tr(),
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
                  const _AlarmPermissionsSection(),
                  gap,
                  WSettingsSectionLabel('settings_tasbih_section'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.timer_outlined,
                        title: 'tasbih_hourly_title'.tr(),
                        subtitle: 'tasbih_hourly_subtitle'.tr(),
                        onTap: () => Modular.to.pushNamed(TasbihRoutes.fullHourly()),
                      ),
                      WSettingsRow(
                        icon: Icons.favorite_border_rounded,
                        title: 'salawat_reminder_title'.tr(),
                        subtitle: 'salawat_reminder_subtitle'.tr(),
                        // Opens the very sheet SNSalawat opens — same cubit
                        // singleton, so the two entry points can't drift.
                        onTap: () => WSalawatReminderSheet.show(context, Modular.get<CBSalawat>()),
                      ),
                    ],
                  ),
                  gap,
                  WSettingsSectionLabel('settings_azkar_section'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.headphones_outlined,
                        title: 'azkar_audio_downloads_title'.tr(),
                        subtitle: 'azkar_audio_downloads_subtitle'.tr(),
                        onTap: () => Modular.to.pushNamed(
                          AzkarRoutes.fullAudioDownloads(),
                        ),
                      ),
                      const WAzkarPreferredReaderRow(),
                    ],
                  ),
                  gap,
                  WSettingsSectionLabel('settings_about_app'.tr()),
                  WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'settings_version'.tr(),
                        subtitle: 'settings_version_hint'.tr(),
                        value: _version,
                        showChevron: false,
                      ),
                    ],
                  ),
                  SizedBox(height: isTab ? 16 : 19.h),
                  const WAppFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final current = LocalizeAndTranslate.getLanguageCode();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              trailing: current == 'ar' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'ar'),
            ),
            ListTile(
              title: const Text('English'),
              trailing: current == 'en' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'en'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || selected == current) return;
    await LocalizeAndTranslate.setLanguageCode(selected);
    if (mounted) setState(() {});
  }
}

/// Android-only section for the two OS grants the over-the-lockscreen adhan
/// depends on. These are system permissions rather than app preferences — they
/// have no owning settings screen to link to, so the grant rows themselves live
/// here, next to the adhan group.
///
/// Collapses to nothing on iOS, where [alarmPermissionInfos] is empty.
class _AlarmPermissionsSection extends StatelessWidget {
  const _AlarmPermissionsSection();

  @override
  Widget build(BuildContext context) {
    return WAlarmPermissionRefresher(
      child: BlocSelector<CBAdhanSettings, SAdhanSettings, AdhanAlarmPermissions>(
        selector: (s) => s.alarmPermissions,
        builder: (context, perms) {
          final infos = alarmPermissionInfos(perms);
          if (infos.isEmpty) return const SizedBox.shrink();
          final cubit = Modular.get<CBAdhanSettings>();
          return Column(
            // Every other section label is a direct sliver child and so spans
            // the list width; without this the Column would centre it instead.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.isTablet ? 12 : 15.h),
              WSettingsSectionLabel('alarm_perm_section'.tr()),
              WSettingsGroup(
                children: [
                  for (final info in infos)
                    WSettingsRow(
                      icon: info.icon,
                      title: info.titleKey.tr(),
                      subtitle: info.subtitleKey.tr(),
                      trailing: WSettingsSwitch(
                        value: info.granted,
                        // Neither direction can be applied in-process; both
                        // flips deep-link to the OS settings page.
                        onChanged: (_) => cubit.openAlarmSetting(info.setting),
                      ),
                      onTap: () => cubit.openAlarmSetting(info.setting),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
