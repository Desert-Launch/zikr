import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/core/utils/helper/link_helper.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_message_card.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_page.dart';

/// Settings › Rate the app: asks for a review, and opens this platform's
/// store listing to leave one.
class SNRateApp extends StatelessWidget {
  const SNRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WSettingsPage(
      title: 'settings_rate_app'.tr(),
      children: [
        WSettingsMessageCard(
          heading: 'settings_rate_heading'.tr(),
          paragraphs: ['settings_rate_body'.tr(), 'settings_rate_reach'.tr()],
          footer: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(Icons.star_rounded, color: AppColorsLight.accent, size: 30.r),
                ],
              ),
              SizedBox(height: 16.h),
              WAppButton(title: 'settings_rate_button'.tr(), onTap: _openStore),
            ],
          ),
        ),
      ],
    );
  }

  /// The App Store's write-a-review page on iOS, the Play listing elsewhere.
  /// Until the app has an App Store id there is no iOS page to open.
  Future<void> _openStore() async {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final url = isIOS ? AppConfig.appStoreReviewUrl : AppConfig.playStoreUrl;
    if (url == null) {
      AppAlert.error('settings_rate_unavailable'.tr());
      return;
    }
    await LinkHelper.open(Uri.parse(url));
  }
}
