import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_lang_tile.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_continue_button.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_header.dart';

class SNLanguageSelection extends StatefulWidget {
  const SNLanguageSelection({super.key});

  @override
  State<SNLanguageSelection> createState() => _SNLanguageSelectionState();
}

class _SNLanguageSelectionState extends State<SNLanguageSelection> {
  late final CBOnboarding _cubit = Modular.get<CBOnboarding>();

  // Only the languages the app actually ships translations for.
  static const _languages = [
    LangOption(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', flag: '🇸🇦'),
    LangOption(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇺🇸'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: Stack(
          children: [
            const WOnboardingBackdrop(),
            SafeArea(
              child: BlocBuilder<CBOnboarding, SOnboarding>(
                builder: (context, state) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 62.h),
                        const WOnboardingHeader(),
                        SizedBox(height: 28.h),
                        ..._languages.map(
                          (l) => WLangTile(
                            opt: l,
                            selected: state.languageCode == l.code,
                            onTap: () => _cubit.setLanguage(l.code),
                          ),
                        ),
                        const Spacer(),
                        WOnboardingContinueButton(onTap: () => Modular.to.pushNamed(OnboardingRoutes.fullLocation())),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
