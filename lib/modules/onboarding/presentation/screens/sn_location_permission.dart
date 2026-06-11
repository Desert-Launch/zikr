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
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_backdrop.dart';

/// Final onboarding step. We don't request the OS permission here — that
/// happens inside Prayer Times when it first needs coordinates. This screen
/// captures the user's *intent* so we can show prayer times immediately if
/// they opted in (and a softer ask later if they didn't).
class SNLocationPermission extends StatelessWidget {
  const SNLocationPermission({super.key});

  static const _features = [
    _FeatureData(
      icon: Icons.location_on_outlined,
      titleKey: 'onboarding_location_feat1_title',
      bodyKey: 'onboarding_location_feat1_body',
    ),
    _FeatureData(
      icon: Icons.near_me_outlined,
      titleKey: 'onboarding_location_feat2_title',
      bodyKey: 'onboarding_location_feat2_body',
    ),
    _FeatureData(
      icon: Icons.shield_outlined,
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColorsLight.primary,
                            AppColorsLight.primaryDark,
                          ],
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
                      child: Icon(Icons.location_on_outlined,
                          color: Colors.white, size: 46.r),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'onboarding_location_title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'onboarding_location_body'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.brand.muted,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    ..._features.map((f) => _FeatureCard(data: f)),
                    const Spacer(),
                    _AllowButton(onTap: () => _finish(context, granted: true)),
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: () => _finish(context, granted: false),
                      child: Text(
                        'onboarding_location_skip'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.brand.muted,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14.r, color: context.brand.muted),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'onboarding_location_note'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.brand.muted,
                            ),
                          ),
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

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});
  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.brand.border),
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
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(data.icon, color: AppColorsLight.primary, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.titleKey.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  data.bodyKey.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.brand.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllowButton extends StatelessWidget {
  const _AllowButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.location_on_outlined, size: 20.r),
        label: Text(
          'onboarding_location_allow'.tr(),
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
