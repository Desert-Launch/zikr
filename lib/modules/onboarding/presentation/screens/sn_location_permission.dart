import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_allow_button.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_feature_card.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';

/// Final onboarding step. We don't request the OS permission here — that
/// happens inside Prayer Times when it first needs coordinates. This screen
/// captures the user's *intent* so we can show prayer times immediately if
/// they opted in (and a softer ask later if they didn't).
class SNLocationPermission extends StatelessWidget {
  const SNLocationPermission({super.key});

  static final _features = [
    FeatureData(
      icon: Assets.icons.location.path,
      titleKey: 'onboarding_location_feat1_title',
      bodyKey: 'onboarding_location_feat1_body',
    ),
    FeatureData(
      icon: Assets.icons.send.path,
      titleKey: 'onboarding_location_feat2_title',
      bodyKey: 'onboarding_location_feat2_body',
    ),
    FeatureData(
      icon: Assets.icons.shield.path,
      titleKey: 'onboarding_location_feat3_title',
      bodyKey: 'onboarding_location_feat3_body',
    ),
  ];

  Future<void> _finish(BuildContext context, {required bool granted}) async {
    final cubit = Modular.get<CBOnboarding>();
    await cubit.setLocationOptIn(granted);
    await cubit.markComplete();
    if (!context.mounted) return;
    Modular.to.navigate(RoutesNames.homeBase);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<CBOnboarding>(),
      child: Scaffold(
        body: Stack(
          children: [
            const WOnboardingBackdrop(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 36.h),
                    Container(
                      width: 96.r,
                      height: 96.r,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0D7E5E), Color(0xff0A6349)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsLight.primary.withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(Assets.icons.location.path),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'onboarding_location_title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 24.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: 300.w,
                      child: Text(
                        'onboarding_location_body'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.sp, color: context.brand.muted, height: 1.6),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    ..._features.map((f) => WFeatureCard(data: f)),
                    SizedBox(height: 28.h),
                    WAllowButton(onTap: () => _finish(context, granted: true)),
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: () => _finish(context, granted: false),
                      child: Text(
                        'onboarding_location_skip'.tr(),
                        style: TextStyle(fontSize: 14.sp, color: context.brand.muted),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'onboarding_location_note'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        SvgPicture.asset(
                          Assets.icons.shield.path,
                          colorFilter: ColorFilter.mode(context.brand.muted, BlendMode.srcIn),
                          width: 12.r,
                          height: 12.r,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
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
