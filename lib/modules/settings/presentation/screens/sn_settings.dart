import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/cubits/cb_theme.dart';
import 'package:quran/core/cubits/s_theme.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';

class SNSettings extends StatefulWidget {
  const SNSettings({super.key});

  @override
  State<SNSettings> createState() => _SNSettingsState();
}

class _SNSettingsState extends State<SNSettings> {
  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF6F5F2);
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SettingsHeader(green: _green)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            sliver: SliverList.list(
              children: [
                const _ProfileCard(green: _green),
                SizedBox(height: 16.h),
                _SectionLabel('settings_general'.tr()),
                BlocBuilder<CBTheme, STheme>(
                  bloc: Modular.get<CBTheme>(),
                  builder: (_, theme) => _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'settings_night_mode'.tr(),
                        subtitle: 'settings_night_mode_hint'.tr(),
                        trailing: Switch.adaptive(
                          value: theme.mode == EThemeMode.dark,
                          activeTrackColor: _green,
                          onChanged: (enabled) =>
                              Modular.get<CBTheme>().setMode(
                                enabled ? EThemeMode.dark : EThemeMode.light,
                              ),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.language_rounded,
                        title: 'settings_language'.tr(),
                        subtitle: 'settings_language_hint'.tr(),
                        value: LocalizeAndTranslate.getLanguageCode() == 'ar'
                            ? 'العربية'
                            : 'English',
                        onTap: _showLanguagePicker,
                      ),
                      _SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'shortcut_reminders'.tr(),
                        subtitle: 'settings_notifications_hint'.tr(),
                        onTap: () =>
                            Modular.to.pushNamed(RoutesNames.remindersBase),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _SectionLabel('settings_quran_section'.tr()),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.menu_book_outlined,
                      title: 'settings_mushaf_type'.tr(),
                      subtitle: 'settings_mushaf_type_hint'.tr(),
                      value: 'settings_mushaf_madani'.tr(),
                      onTap: () => Modular.to.pushNamed(RoutesNames.quranBase),
                    ),
                    _SettingsRow(
                      icon: Icons.palette_outlined,
                      title: 'settings_theme_style'.tr(),
                      subtitle: 'settings_theme_style_hint'.tr(),
                      value: _themeLabel(Modular.get<CBTheme>().state.mode),
                      onTap: _showThemePicker,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _SectionLabel('settings_about_app'.tr()),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'legal_about'.tr(),
                      subtitle: 'settings_about_hint'.tr(),
                      onTap: () =>
                          Modular.to.pushNamed(LegalRoutes.fullAbout()),
                    ),
                    _SettingsRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'legal_privacy'.tr(),
                      subtitle: 'settings_privacy_hint'.tr(),
                      onTap: () =>
                          Modular.to.pushNamed(LegalRoutes.fullPrivacy()),
                    ),
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'settings_version'.tr(),
                      subtitle: 'settings_version_hint'.tr(),
                      value: _version,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _AppFooter(green: _green),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.green});

  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126.h,
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 24.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: Modular.to.pop,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'settings_title'.tr(),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'settings_subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.green});

  final Color green;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAuth, SAuth>(
      bloc: Modular.get<CBAuth>(),
      builder: (_, state) {
        final user = state.user;
        return InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
            if (state.isLoggedIn) {
              _confirmLogout(context);
            } else {
              Modular.to.pushNamed(AuthRoutes.fullLogin());
            }
          },
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE5E8E5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        user?.name ?? 'settings_guest_user'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        user?.email ?? 'settings_guest_email'.tr(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        state.isLoggedIn
                            ? 'settings_logout'.tr()
                            : 'auth_login'.tr(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: green,
                  backgroundImage: user?.avatar != null
                      ? NetworkImage(user!.avatar!)
                      : null,
                  child: user?.avatar == null
                      ? Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 25.r,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings_logout_confirm_title'.tr()),
        content: Text('settings_logout_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common_cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColorsLight.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('settings_logout'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Modular.get<CBAuth>().logout();
    if (context.mounted) Modular.to.navigate(RoutesNames.homeBase);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 6.w, bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 14.w, endIndent: 14.w),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            if (trailing != null)
              SizedBox(
                width: 44.w,
                height: 28.h,
                child: FittedBox(child: trailing),
              )
            else if (value != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, size: 16.r),
                  SizedBox(width: 3.w),
                  Text(
                    value!,
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[700]),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_left_rounded, size: 16.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(width: 9.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: const Color(0xFFE8F5F0),
              child: Icon(icon, color: _SNSettingsState._green, size: 16.r),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter({required this.green});

  final Color green;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: green,
          child: const Icon(Icons.star_rounded, color: Color(0xFFD6A72C)),
        ),
        SizedBox(height: 7.h),
        Text(
          'home_page_title'.tr(),
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 3.h),
        Text(
          'settings_footer'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
