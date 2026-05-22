import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';

class SNLanguageSelection extends StatefulWidget {
  const SNLanguageSelection({super.key});

  @override
  State<SNLanguageSelection> createState() => _SNLanguageSelectionState();
}

class _SNLanguageSelectionState extends State<SNLanguageSelection> {
  late final CBOnboarding _cubit = Modular.get<CBOnboarding>();

  static const _languages = [
    _LangOption(code: 'ar', nativeName: 'العربية', englishName: 'Arabic'),
    _LangOption(code: 'en', nativeName: 'English', englishName: 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text('onboarding_language_title'.tr()),
        ),
        body: SafeArea(
          child: BlocBuilder<CBOnboarding, SOnboarding>(
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'onboarding_language_body'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp, color: context.brand.muted,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ..._languages.map((l) => _LangTile(
                          opt: l,
                          selected: state.languageCode == l.code,
                          onTap: () => _cubit.setLanguage(l.code),
                        )),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Modular.to.pushNamed(OnboardingRoutes.fullLocation()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColorsLight.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('common_continue'.tr(),
                            style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LangOption {
  const _LangOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });
  final String code;
  final String nativeName;
  final String englishName;
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  final _LangOption opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColorsLight.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? AppColorsLight.primary
                  : context.brand.border,
              width: selected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColorsLight.primary : context.brand.muted,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.nativeName,
                        style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w700,
                        )),
                    Text(opt.englishName,
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
  }
}
