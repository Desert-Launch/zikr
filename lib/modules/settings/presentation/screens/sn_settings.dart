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
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';

class SNSettings extends StatefulWidget {
  const SNSettings({super.key});

  @override
  State<SNSettings> createState() => _SNSettingsState();
}

class _SNSettingsState extends State<SNSettings> {
  static const _green = Color(0xFF2F7E63);
  static const _greenDark = Color(0xFF286B55);
  static const _gold = Color(0xFFD9B947);
  static const _canvas = Color(0xFFFAF9F7);
  static const _border = Color(0xFFE2ECE8);
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
          const SliverToBoxAdapter(child: _SettingsHeader()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(19.w, 18.h, 19.w, 24.h),
            sliver: SliverList.list(
              children: [
                const _ProfileCard(),
                SizedBox(height: 15.h),
                _SectionLabel('settings_general'.tr()),
                BlocBuilder<CBTheme, STheme>(
                  bloc: Modular.get<CBTheme>(),
                  builder: (_, theme) => _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'settings_night_mode'.tr(),
                        subtitle: 'settings_night_mode_hint'.tr(),
                        leading: _NightModeSwitch(
                          enabled: theme.mode == EThemeMode.dark,
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
                        title: 'settings_notifications'.tr(),
                        subtitle: 'settings_notifications_hint'.tr(),
                        onTap: () =>
                            Modular.to.pushNamed(RoutesNames.remindersBase),
                      ),
                      _SettingsRow(
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
                    BlocBuilder<CBTheme, STheme>(
                      bloc: Modular.get<CBTheme>(),
                      builder: (_, theme) => _SettingsRow(
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
                      icon: Icons.info_outline_rounded,
                      title: 'settings_version'.tr(),
                      subtitle: 'settings_version_hint'.tr(),
                      value: _version,
                      showChevron: false,
                    ),
                  ],
                ),
                SizedBox(height: 19.h),
                const _AppFooter(),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_SNSettingsState._green, _SNSettingsState._greenDark],
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            PositionedDirectional(
              top: -57.r,
              start: -13.r,
              child: const _HeaderCircle(size: 112),
            ),
            PositionedDirectional(
              bottom: -51.r,
              end: -24.r,
              child: const _HeaderCircle(size: 94),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(23.w, 10.h, 23.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Modular.to.pop,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
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
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'settings_subtitle'.tr(),
                          style: GoogleFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 11.sp,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
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

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.045),
          width: 4.r,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAuth, SAuth>(
      bloc: Modular.get<CBAuth>(),
      builder: (_, state) {
        final user = state.user;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19.r),
            border: Border.all(color: _SNSettingsState._border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              _ProfileAvatar(avatar: user?.avatar),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'settings_guest_user'.tr(),
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFF2C2C2C),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.sp,
                        color: const Color(0xFF7C7C7C),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    InkWell(
                      onTap: () => Modular.to.pushNamed(AuthRoutes.fullLogin()),
                      child: Text(
                        'settings_edit_profile'.tr(),
                        style: GoogleFonts.tajawal(
                          color: _SNSettingsState._green,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.avatar});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58.r,
      height: 58.r,
      decoration: BoxDecoration(
        color: _SNSettingsState._green,
        borderRadius: BorderRadius.circular(22.r),
        image: avatar != null
            ? DecorationImage(image: NetworkImage(avatar!), fit: BoxFit.cover)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: avatar == null
          ? Icon(Icons.person_outline_rounded, color: Colors.white, size: 29.r)
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 7.h),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 10.sp,
          color: const Color(0xFF777777),
          height: 1,
        ),
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
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: _SNSettingsState._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(
                  height: 1,
                  indent: 14.w,
                  endIndent: 14.w,
                  color: const Color(0xFFEDF1EF),
                ),
            ],
          ],
        ),
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
    this.leading,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 72.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 11.h),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFF303030),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 9.sp,
                        color: const Color(0xFF858585),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (leading != null)
                leading!
              else
                _RowValue(value: value, showChevron: showChevron),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.r,
      height: 38.r,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F4ED),
      ),
      child: Icon(icon, color: _SNSettingsState._green, size: 19.r),
    );
  }
}

class _RowValue extends StatelessWidget {
  const _RowValue({required this.value, required this.showChevron});

  final String? value;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    if (value != null && !showChevron) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E8E5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          value!.isEmpty ? '1.0.0' : value!,
          style: GoogleFonts.tajawal(
            fontSize: 9.sp,
            color: const Color(0xFF777777),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showChevron)
          Icon(
            Icons.chevron_left_rounded,
            color: const Color(0xFF6F6F6F),
            size: 21.r,
          ),
        if (value != null) ...[
          SizedBox(width: 7.w),
          Text(
            value!,
            style: GoogleFonts.tajawal(
              fontSize: 10.sp,
              color: const Color(0xFF717171),
            ),
          ),
        ],
      ],
    );
  }
}

class _NightModeSwitch extends StatelessWidget {
  const _NightModeSwitch({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75,
      child: Switch(
        value: enabled,
        activeTrackColor: _SNSettingsState._green,
        inactiveTrackColor: const Color(0xFFF7F7F7),
        inactiveThumbColor: Colors.white,
        trackOutlineColor: WidgetStateProperty.all(const Color(0xFFEDEDED)),
        thumbColor: WidgetStateProperty.all(Colors.white),
        onChanged: onChanged,
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 51.r,
          height: 51.r,
          decoration: BoxDecoration(
            color: _SNSettingsState._green,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.star_rounded,
            color: _SNSettingsState._gold,
            size: 27.r,
          ),
        ),
        SizedBox(height: 11.h),
        Text(
          'home_page_title'.tr(),
          style: GoogleFonts.tajawal(
            fontSize: 12.sp,
            color: const Color(0xFF777777),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'settings_footer'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 9.sp,
            color: const Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }
}
