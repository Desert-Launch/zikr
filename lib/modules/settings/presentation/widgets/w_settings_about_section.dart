import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The "About the app" block at the foot of Settings: contact, the about and
/// privacy pages (owned by the legal module), sharing the app, and the version.
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
              onTap: _contactUs,
            ),
            WSettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'legal_about'.tr(),
              subtitle: 'settings_about_hint'.tr(),
              onTap: () => Modular.to.pushNamed(LegalRoutes.fullAbout()),
            ),
            WSettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'legal_privacy'.tr(),
              subtitle: 'settings_privacy_hint'.tr(),
              onTap: () => Modular.to.pushNamed(LegalRoutes.fullPrivacy()),
            ),
            // Builder so the share sheet's iPad popover can point at this row.
            Builder(
              builder: (rowContext) => WSettingsRow(
                icon: Icons.share_outlined,
                title: 'settings_share_app'.tr(),
                subtitle: 'settings_share_app_hint'.tr(),
                onTap: () => _shareApp(rowContext),
              ),
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

  /// Opens the reader's mail app on a message to [AppConfig.supportEmail]. The
  /// subject carries the version so a report says which build it is about.
  Future<void> _contactUs() async {
    final subject = [
      'settings_contact_subject'.tr(),
      if (_version.isNotEmpty) '(v$_version)',
    ].join(' ');
    // Built by hand: `queryParameters` encodes spaces as `+`, which mail apps
    // show literally in the subject line.
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      AppLogger.error('opening the mail app failed', error: e, stackTrace: st, tag: 'WSettingsAboutSection');
    }
    if (!opened) {
      AppAlert.error('settings_contact_failed'.tr().replaceFirst('{{email}}', AppConfig.supportEmail));
    }
  }

  Future<void> _shareApp(BuildContext rowContext) async {
    final box = rowContext.findRenderObject();
    final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
    await Share.share(
      'settings_share_app_text'.tr().replaceFirst('{{url}}', AppConfig.shareAppUrl),
      sharePositionOrigin: origin,
    );
  }
}
