import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/utils/helper/link_helper.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_message_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_page.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';

/// Settings › Contact us: a short note, then the app's channels — website,
/// support email, Facebook and Instagram — each opening in its own app.
class SNContactUs extends StatefulWidget {
  const SNContactUs({super.key});

  @override
  State<SNContactUs> createState() => _SNContactUsState();
}

class _SNContactUsState extends State<SNContactUs> {
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
    return WSettingsPage(
      title: 'settings_contact_us'.tr(),
      children: [
        WSettingsMessageCard(paragraphs: ['settings_contact_intro'.tr()]),
        SizedBox(height: 15.h),
        WSettingsGroup(
          children: [
            WSettingsRow(
              icon: Icons.public_rounded,
              title: 'settings_contact_website'.tr(),
              subtitle: AppConfig.websiteUrl.replaceFirst('https://', ''),
              onTap: () => LinkHelper.open(Uri.parse(AppConfig.websiteUrl)),
            ),
            WSettingsRow(
              icon: Icons.mail_outline_rounded,
              title: 'settings_contact_email'.tr(),
              subtitle: AppConfig.supportEmail,
              onTap: _email,
            ),
            WSettingsRow(
              icon: Icons.facebook_rounded,
              title: 'settings_contact_facebook'.tr(),
              subtitle: AppConfig.facebookUrl.split('/').last,
              onTap: () => LinkHelper.open(Uri.parse(AppConfig.facebookUrl)),
            ),
            WSettingsRow(
              icon: Icons.camera_alt_outlined,
              title: 'settings_contact_instagram'.tr(),
              // The left-to-right mark keeps the "@" in front of the handle in
              // an Arabic line, where it would otherwise drift to its end.
              subtitle: '‎@${AppConfig.instagramHandle}',
              onTap: () => LinkHelper.open(Uri.parse(AppConfig.instagramUrl)),
            ),
          ],
        ),
      ],
    );
  }

  /// Opens the reader's mail app on a message to [AppConfig.supportEmail]. The
  /// subject carries the version so a report says which build it is about.
  Future<void> _email() {
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
    return LinkHelper.open(
      uri,
      failureMessage: 'settings_contact_failed'.tr().replaceFirst('{{email}}', AppConfig.supportEmail),
    );
  }
}
