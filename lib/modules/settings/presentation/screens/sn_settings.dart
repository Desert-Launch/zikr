import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/cubits/cb_theme.dart';
import 'package:quran/core/cubits/s_theme.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/settings/presentation/widgets/w_app_footer.dart';
import 'package:quran/modules/settings/presentation/widgets/w_night_mode_switch.dart';
import 'package:quran/modules/settings/presentation/widgets/w_profile_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_header.dart';
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
    return Scaffold(
      backgroundColor: _canvas,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: WSettingsHeader()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(19.w, 18.h, 19.w, 24.h),
            sliver: SliverList.list(
              children: [
                const WProfileCard(),
                SizedBox(height: 15.h),
                WSettingsSectionLabel('settings_general'.tr()),
                BlocBuilder<CBTheme, STheme>(
                  bloc: Modular.get<CBTheme>(),
                  builder: (_, theme) => WSettingsGroup(
                    children: [
                      WSettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'settings_night_mode'.tr(),
                        subtitle: 'settings_night_mode_hint'.tr(),
                        leading: WNightModeSwitch(
                          enabled: theme.mode == EThemeMode.dark,
                          onChanged: (enabled) =>
                              Modular.get<CBTheme>().setMode(
                                enabled ? EThemeMode.dark : EThemeMode.light,
                              ),
                        ),
                      ),
                      WSettingsRow(
                        icon: Icons.language_rounded,
                        title: 'settings_language'.tr(),
                        subtitle: 'settings_language_hint'.tr(),
                        value: LocalizeAndTranslate.getLanguageCode() == 'ar'
                            ? 'العربية'
                            : 'English',
                        onTap: _showLanguagePicker,
                      ),
                      WSettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'settings_notifications'.tr(),
                        subtitle: 'settings_notifications_hint'.tr(),
                        onTap: () =>
                            Modular.to.pushNamed(RoutesNames.remindersBase),
                      ),
                      WSettingsRow(
                        icon: Icons.access_time_rounded,
                        title: 'prayer_settings_title'.tr(),
                        subtitle: 'settings_adhan_hint'.tr(),
                        onTap: () =>
                            Modular.to.pushNamed(AdhanRoutes.overview()),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                WSettingsSectionLabel('settings_quran_section'.tr()),
                WSettingsGroup(
                  children: [
                    WSettingsRow(
                      icon: Icons.menu_book_outlined,
                      title: 'settings_mushaf_type'.tr(),
                      subtitle: 'settings_mushaf_type_hint'.tr(),
                      value: 'settings_mushaf_madani'.tr(),
                      onTap: () => Modular.to.pushNamed(RoutesNames.quranBase),
                    ),
                    BlocBuilder<CBTheme, STheme>(
                      bloc: Modular.get<CBTheme>(),
                      builder: (_, theme) => WSettingsRow(
                        icon: Icons.palette_outlined,
                        title: 'settings_theme_style'.tr(),
                        subtitle: 'settings_theme_style_hint'.tr(),
                        value: _themeLabel(theme.mode),
                        onTap: _showThemePicker,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                WSettingsSectionLabel('settings_about_app'.tr()),
                WSettingsGroup(
                  children: [
                    WSettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'legal_about'.tr(),
                      subtitle: 'settings_about_hint'.tr(),
                      onTap: () =>
                          Modular.to.pushNamed(LegalRoutes.fullAbout()),
                    ),
                    WSettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'settings_version'.tr(),
                      subtitle: 'settings_version_hint'.tr(),
                      value: _version,
                      showChevron: false,
                    ),
                  ],
                ),
                SizedBox(height: 19.h),
                const WAppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(EThemeMode mode) => switch (mode) {
    EThemeMode.system => 'settings_theme_system'.tr(),
    EThemeMode.light => 'settings_theme_light'.tr(),
    EThemeMode.dark => 'settings_theme_dark'.tr(),
  };

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

  Future<void> _showThemePicker() async {
    final selected = await showModalBottomSheet<EThemeMode>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: EThemeMode.values
              .map(
                (mode) => ListTile(
                  title: Text(_themeLabel(mode)),
                  trailing: Modular.get<CBTheme>().state.mode == mode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, mode),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) await Modular.get<CBTheme>().setMode(selected);
  }
}
