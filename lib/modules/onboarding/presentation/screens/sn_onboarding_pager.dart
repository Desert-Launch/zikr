import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_bottom_bar.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_dots.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_slide.dart';

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
    SlideData(
      icon: Icons.menu_book_rounded,
      titleKey: 'onboarding_slide1_title',
      bodyKey: 'onboarding_slide1_body',
      gold: false,
    ),
    SlideData(
      icon: Icons.access_time_rounded,
      titleKey: 'onboarding_slide2_title',
      bodyKey: 'onboarding_slide2_body',
      gold: true,
    ),
    SlideData(
      icon: Icons.favorite_rounded,
      titleKey: 'onboarding_slide3_title',
      bodyKey: 'onboarding_slide3_body',
      gold: false,
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

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip() => Modular.to.pushNamed(OnboardingRoutes.fullLanguage());

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
                  final isLast = state.pageIndex == _slides.length - 1;
                  final accent = _slides[state.pageIndex].gold
                      ? AppColorsLight.accent
                      : AppColorsLight.primary;
                  return Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: _cubit.setPage,
                          itemBuilder: (_, i) => WSlide(data: _slides[i]),
                        ),
                      ),
                      WDots(count: _slides.length, index: state.pageIndex, color: accent),
                      SizedBox(height: 24.h),
                      WBottomBar(
                        accent: accent,
                        isLast: isLast,
                        showBack: state.pageIndex > 0,
                        onNext: _next,
                        onBack: _back,
                        onSkip: _skip,
                      ),
                      SizedBox(height: 16.h),
                    ],
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
