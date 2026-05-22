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

class SNOnboardingPager extends StatefulWidget {
  const SNOnboardingPager({super.key});

  @override
  State<SNOnboardingPager> createState() => _SNOnboardingPagerState();
}

class _SNOnboardingPagerState extends State<SNOnboardingPager> {
  late final CBOnboarding _cubit = Modular.get<CBOnboarding>();
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const _slides = [
    _SlideData(
      icon: Icons.menu_book_rounded,
      titleKey: 'onboarding_slide1_title',
      bodyKey: 'onboarding_slide1_body',
    ),
    _SlideData(
      icon: Icons.headphones_rounded,
      titleKey: 'onboarding_slide2_title',
      bodyKey: 'onboarding_slide2_body',
    ),
    _SlideData(
      icon: Icons.mosque_rounded,
      titleKey: 'onboarding_slide3_title',
      bodyKey: 'onboarding_slide3_body',
    ),
  ];

  void _next() {
    if (_pageController.page!.round() < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      Modular.to.pushNamed(OnboardingRoutes.fullLanguage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<CBOnboarding, SOnboarding>(
            builder: (context, state) {
              return Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () =>
                          Modular.to.pushNamed(OnboardingRoutes.fullLanguage()),
                      child: Text('onboarding_skip'.tr()),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: _cubit.setPage,
                      itemBuilder: (_, i) => _Slide(data: _slides[i]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: i == state.pageIndex ? 22.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: i == state.pageIndex
                              ? AppColorsLight.primary
                              : context.brand.border,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColorsLight.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          state.pageIndex < _slides.length - 1
                              ? 'common_continue'.tr()
                              : 'onboarding_get_started'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140.r,
            height: 140.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(data.icon,
                color: AppColorsLight.accent, size: 64.r),
          ),
          SizedBox(height: 28.h),
          Text(
            data.titleKey.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 22.sp, fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            data.bodyKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.brand.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
