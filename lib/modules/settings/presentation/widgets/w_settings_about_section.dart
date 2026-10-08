import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';

/// The "About the app" block at the foot of Settings: contact, the about,
/// terms and privacy pages (owned by the legal module), sharing and rating the
/// app, and the version.
class WSettingsAboutSection extends StatefulWidget {
  const WSettingsAboutSection({super.key});

  @override
  State<WSettingsAboutSection> createState() => _WSettingsAboutSectionState();
}

class _WSettingsAboutSectionState extends State<WSettingsAboutSection> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WSettingsSectionLabel('settings_about_app'.tr()),
        WSettingsGroup(
          children: [
            WSettingsRow(
              icon: Icons.mail_outline_rounded,
              title: 'settings_contact_us'.tr(),
              subtitle: 'settings_contact_us_hint'.tr(),
              onTap: () => Modular.to.pushNamed(SettingsRoutes.fullContact()),
            ),
            WSettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'legal_about'.tr(),
              subtitle: 'settings_about_hint'.tr(),
              onTap: () => Modular.to.pushNamed(LegalRoutes.fullAbout()),
            ),
            WSettingsRow(
              icon: Icons.description_outlined,
              title: 'legal_terms'.tr(),
              subtitle: 'settings_terms_hint'.tr(),
              onTap: () => Modular.to.pushNamed(LegalRoutes.fullTerms()),
            ),
            WSettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'legal_privacy'.tr(),
              subtitle: 'settings_privacy_hint'.tr(),
              onTap: () => Modular.to.pushNamed(LegalRoutes.fullPrivacy()),
            ),
            WSettingsRow(
              icon: Icons.share_outlined,
              title: 'settings_share_app'.tr(),
              subtitle: 'settings_share_app_hint'.tr(),
              onTap: () => Modular.to.pushNamed(SettingsRoutes.fullShare()),
            ),
            WSettingsRow(
              icon: Icons.star_outline_rounded,
              title: 'settings_rate_app'.tr(),
              subtitle: 'settings_rate_app_hint'.tr(),
              onTap: () => Modular.to.pushNamed(SettingsRoutes.fullRate()),
            ),
            WSettingsRow(
              icon: Icons.tag_rounded,
              title: 'settings_version'.tr(),
              subtitle: 'settings_version_hint'.tr(),
              value: _version,
              showChevron: false,
            ),
          ],
        ),
      ],
    );
  }
}
