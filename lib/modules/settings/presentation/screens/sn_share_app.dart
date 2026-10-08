import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_message_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_page.dart';
import 'package:share_plus/share_plus.dart';

/// Settings › Share the app: the hadith on guiding others to good, and a
/// button that shares the app's link.
class SNShareApp extends StatelessWidget {
  const SNShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WSettingsPage(
      title: 'settings_share_app'.tr(),
      children: [
        WSettingsMessageCard(
          heading: 'settings_share_heading'.tr(),
          quote: 'settings_share_hadith'.tr(),
          paragraphs: ['settings_share_body'.tr()],
          // Builder so the share sheet's iPad popover can point at the button.
          footer: Builder(
            builder: (buttonContext) => WAppButton(
              title: 'settings_share_button'.tr(),
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onTap: () => _share(buttonContext),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
    await Share.share(
      'settings_share_app_text'.tr().replaceFirst('{{url}}', AppConfig.shareAppUrl),
      sharePositionOrigin: origin,
    );
  }
}
