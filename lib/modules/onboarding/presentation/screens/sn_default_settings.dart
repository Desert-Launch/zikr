import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_feature_card.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_continue_button.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_header.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_lock_screen.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_lock_screen.dart';

/// Closing onboarding step: what a new install starts with switched on, and
/// where to change it.
///
/// A fresh install ships with every feature on — the adhan and sunrise
/// alerts, the azkar and salawat reminders, and on Android the lock-screen
/// prayer notification, which [CBOnboarding.markComplete] switches on as this
/// screen finishes. So nothing here asks; it tells, and points at Settings.
class SNDefaultSettings extends StatefulWidget {
  const SNDefaultSettings({super.key});

  @override
  State<SNDefaultSettings> createState() => _SNDefaultSettingsState();
}

class _SNDefaultSettingsState extends State<SNDefaultSettings> {
  /// Holds the button off while [CBOnboarding.markComplete] runs, so a second
  /// tap can't finish onboarding twice.
  bool _finishing = false;

  static final _features = [
    FeatureData(
      icon: Assets.icons.bell.path,
      titleKey: 'onboarding_defaults_adhan_title',
      bodyKey: 'onboarding_defaults_adhan_body',
    ),
    FeatureData(
      icon: Assets.icons.heart.path,
      titleKey: 'onboarding_defaults_azkar_title',
      bodyKey: 'onboarding_defaults_azkar_body',
    ),
  ];

  /// Android only — iOS has no lock-screen form an app can switch on.
  static final _lockScreenFeature = FeatureData(
    icon: Assets.icons.clock.path,
    titleKey: 'onboarding_defaults_lock_title',
    bodyKey: 'onboarding_defaults_lock_body',
  );

  Future<void> _finish() async {
    setState(() => _finishing = true);
    await Modular.get<CBOnboarding>().markComplete();
    if (!mounted) return;
    Modular.to.navigate(RoutesNames.homeBase);
  }

  @override
  Widget build(BuildContext context) {
    final pinsLockScreen =
        Modular.get<CBPrayerLockScreen>().state.mode == ELockScreenMode.notification;
    return Scaffold(
      body: Stack(
        children: [
          const WOnboardingBackdrop(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 32.h),
                  WOnboardingHeader(
                    icon: Icons.tune_rounded,
                    title: 'onboarding_defaults_title'.tr(),
                    subtitle: 'onboarding_defaults_subtitle'.tr(),
                  ),
                  SizedBox(height: 24.h),
                  ..._features.map((f) => WFeatureCard(data: f)),
                  if (pinsLockScreen) WFeatureCard(data: _lockScreenFeature),
                  SizedBox(height: 4.h),
                  const _SettingsHint(),
                  const Spacer(),
                  WOnboardingContinueButton(
                    labelKey: 'onboarding_get_started',
                    onTap: _finishing ? null : _finish,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "You can change all of this in Settings", with the settings glyph so the
/// user knows what to look for.
class _SettingsHint extends StatelessWidget {
  const _SettingsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_outlined, size: 22.r, color: AppColorsLight.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'onboarding_defaults_note'.tr(),
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
