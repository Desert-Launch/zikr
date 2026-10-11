import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_continue_button.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_header.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_privacy_accept_tile.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_privacy_policy_card.dart';

/// First onboarding step: the privacy policy on its own, with the consent
/// checkbox that gates moving on to the language picker.
class SNPrivacyConsent extends StatefulWidget {
  const SNPrivacyConsent({super.key});

  @override
  State<SNPrivacyConsent> createState() => _SNPrivacyConsentState();
}

class _SNPrivacyConsentState extends State<SNPrivacyConsent> {
  late final CBOnboarding _cubit = Modular.get<CBOnboarding>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
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
                      icon: Icons.privacy_tip_outlined,
                      title: 'legal_privacy'.tr(),
                      subtitle: 'onboarding_privacy_subtitle'.tr(),
                    ),
                    SizedBox(height: 24.h),
                    Expanded(
                      child: BlocSelector<CBOnboarding, SOnboarding, String>(
                        selector: (s) => s.languageCode,
                        builder: (_, code) => WPrivacyPolicyCard(languageCode: code),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    BlocSelector<CBOnboarding, SOnboarding, bool>(
                      selector: (s) => s.privacyAccepted,
                      builder: (_, accepted) => Column(
                        children: [
                          WPrivacyAcceptTile(
                            value: accepted,
                            onChanged: _cubit.setPrivacyAccepted,
                          ),
                          SizedBox(height: 12.h),
                          WOnboardingContinueButton(
                            onTap: accepted
                                ? () => Modular.to.pushNamed(OnboardingRoutes.fullLanguage())
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
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
