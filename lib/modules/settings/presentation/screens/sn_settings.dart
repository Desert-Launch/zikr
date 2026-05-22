import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';
import 'package:quran/modules/settings/presentation/widgets/w_language_picker.dart';
import 'package:quran/modules/settings/presentation/widgets/w_theme_picker.dart';

class SNSettings extends StatefulWidget {
  const SNSettings({super.key});

  @override
  State<SNSettings> createState() => _SNSettingsState();
}

class _SNSettingsState extends State<SNSettings> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        children: [
          const _ProfileCard(),
          SizedBox(height: 16.h),
          _Section(
            title: 'settings_appearance'.tr(),
            child: const WThemePicker(),
          ),
          _Section(
            title: 'settings_language'.tr(),
            child: const WLanguagePicker(),
          ),
          _Section(
            title: 'settings_about'.tr(),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text('legal_privacy'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Modular.to.pushNamed(LegalRoutes.fullPrivacy()),
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded),
                  title: Text('legal_terms'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Modular.to.pushNamed(LegalRoutes.fullTerms()),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text('legal_about'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Modular.to.pushNamed(LegalRoutes.fullAbout()),
                ),
                ListTile(
                  leading: const Icon(Icons.tag_rounded),
                  title: Text('settings_version'.tr()),
                  trailing: Text(
                    _version,
                    style: TextStyle(
                      fontSize: 12.sp, color: context.brand.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'settings_account'.tr(),
            child: BlocBuilder<CBAuth, SAuth>(
              bloc: Modular.get<CBAuth>(),
              builder: (context, state) {
                if (!state.isLoggedIn) return const SizedBox.shrink();
                return ListTile(
                  leading: Icon(Icons.logout_rounded,
                      color: AppColorsLight.error),
                  title: Text(
                    'settings_logout'.tr(),
                    style: TextStyle(color: AppColorsLight.error),
                  ),
                  onTap: () => _confirmLogout(context),
                );
              },
            ),
          ),
        ],
      ),
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
    if (!context.mounted) return;
    Modular.to.navigate(RoutesNames.authBase);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: context.brand.muted,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            elevation: 0,
            child: child,
          ),
        ],
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
      builder: (context, state) {
        final user = state.user;
        if (user == null) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text('settings_not_signed_in'.tr(),
                style: TextStyle(fontSize: 13.sp)),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor:
                        AppColorsLight.primary.withValues(alpha: 0.1),
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: user.avatar == null
                        ? Icon(Icons.person, color: AppColorsLight.primary)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.w700,
                            )),
                        SizedBox(height: 2.h),
                        Text(user.email,
                            style: TextStyle(
                              fontSize: 12.sp, color: context.brand.muted,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
