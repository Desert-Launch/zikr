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
import 'package:quran/modules/settings/presentation/widgets/w_app_footer.dart';
import 'package:quran/modules/settings/presentation/widgets/w_profile_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';

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
                  SizedBox(height: isTab ? 12 : 15.h),
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
                      WSettingsRow(
                        icon: Icons.access_time_rounded,
                        title: 'prayer_settings_title'.tr(),
                        subtitle: 'settings_adhan_hint'.tr(),
                        onTap: () => Modular.to.pushNamed(AdhanRoutes.overview()),
                      ),
                    ],
                  ),
                  const _AlarmPermissionsSection(),
                  SizedBox(height: isTab ? 12 : 15.h),
                  WSettingsSectionLabel('settings_about_app'.tr()),
                  WSettingsGroup(
                    children: [
                      // WSettingsRow(
                      //   icon: Icons.info_outline_rounded,
                      //   title: 'legal_about'.tr(),
                      //   subtitle: 'settings_about_hint'.tr(),
                      //   onTap: () => Modular.to.pushNamed(LegalRoutes.fullAbout()),
                      // ),
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
/// depends on. Duplicated here (they also live in the adhan screen) because a
/// user who skipped them during onboarding looks in Settings first.
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
                      leading: WAlarmPermissionSwitch(
                        granted: info.granted,
                        onTap: () => cubit.openAlarmSetting(info.setting),
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
