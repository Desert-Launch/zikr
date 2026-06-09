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

/// Darker gold used as the gradient end-stop for the prayer-times slide.
const Color _goldDark = Color(0xFFA8851C);

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
      gold: false,
    ),
    _SlideData(
      icon: Icons.access_time_rounded,
      titleKey: 'onboarding_slide2_title',
      bodyKey: 'onboarding_slide2_body',
      gold: true,
    ),
    _SlideData(
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
                          itemBuilder: (_, i) => _Slide(data: _slides[i]),
                        ),
                      ),
                      _Dots(count: _slides.length, index: state.pageIndex, color: accent),
                      SizedBox(height: 24.h),
                      _BottomBar(
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

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.gold,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final bool gold;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final accent = data.gold ? AppColorsLight.accent : AppColorsLight.primary;
    final accentDark = data.gold ? _goldDark : AppColorsLight.primaryDark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Faint ring encircling the icon, echoing the mockup.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 230.r,
                height: 230.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.10),
                    width: 1.4,
                  ),
                ),
              ),
              Container(
                width: 104.r,
                height: 104.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 48.r),
              ),
            ],
          ),
          SizedBox(height: 36.h),
          Text(
            data.titleKey.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            data.bodyKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.brand.muted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});
  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: i == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: i == index ? color : context.brand.border,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.accent,
    required this.isLast,
    required this.showBack,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final Color accent;
  final bool isLast;
  final bool showBack;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkip,
            child: Text(
              'onboarding_skip'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: context.brand.muted,
              ),
            ),
          ),
          Row(
            children: [
              if (showBack) ...[
                _CircleButton(accent: accent, onTap: onBack),
                SizedBox(width: 12.w),
              ],
              _NextButton(
                accent: accent,
                label: isLast
                    ? 'onboarding_get_started'.tr()
                    : 'onboarding_next'.tr(),
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.accent,
    required this.label,
    required this.onTap,
  });
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent == AppColorsLight.accent
                    ? _goldDark
                    : AppColorsLight.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.brand.surface,
            border: Border.all(color: context.brand.border),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: context.brand.muted,
            size: 22.r,
          ),
        ),
      ),
    );
  }
}
