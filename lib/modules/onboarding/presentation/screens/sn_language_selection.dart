import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';

class SNLanguageSelection extends StatefulWidget {
  const SNLanguageSelection({super.key});

  @override
  State<SNLanguageSelection> createState() => _SNLanguageSelectionState();
}

class _SNLanguageSelectionState extends State<SNLanguageSelection> {
  late final CBOnboarding _cubit = Modular.get<CBOnboarding>();

  // Only the languages the app actually ships translations for.
  static const _languages = [
    _LangOption(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', flag: '🇸🇦'),
    _LangOption(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇺🇸'),
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
                        SizedBox(height: 32.h),
                        const _Header(),
                        SizedBox(height: 28.h),
                        ..._languages.map((l) => _LangTile(
                              opt: l,
                              selected: state.languageCode == l.code,
                              onTap: () => _cubit.setLanguage(l.code),
                            )),
                        const Spacer(),
                        _ContinueButton(
                          onTap: () => Modular.to
                              .pushNamed(OnboardingRoutes.fullLocation()),
                        ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84.r,
          height: 84.r,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: AppColorsLight.primary.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(Icons.language_rounded, color: Colors.white, size: 42.r),
        ),
        SizedBox(height: 16.h),
        Text(
          'onboarding_language_title'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'onboarding_language_subtitle'.tr(),
          style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
        ),
      ],
    );
  }
}

class _LangOption {
  const _LangOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
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
      padding: EdgeInsets.only(bottom: 14.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: context.brand.surface,
              border: Border.all(
                color: selected ? AppColorsLight.primary : context.brand.border,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(opt.flag, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.nativeName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        opt.englishName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.brand.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _CheckCircle(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColorsLight.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColorsLight.primary : context.brand.border,
          width: 1.6,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: Colors.white, size: 16.r)
          : null,
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          'common_continue'.tr(),
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
