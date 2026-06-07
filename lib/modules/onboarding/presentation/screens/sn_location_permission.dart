import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';

/// Final onboarding step. We don't request the OS permission here — that
/// happens inside Prayer Times when it first needs coordinates. This screen
/// captures the user's *intent* so we can show prayer times immediately if
/// they opted in (and a softer ask later if they didn't).
class SNLocationPermission extends StatelessWidget {
  const SNLocationPermission({super.key});

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
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColorsLight.primary,
                    size: 56.r,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'onboarding_location_title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'onboarding_location_body'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.brand.muted,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _finish(context, granted: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColorsLight.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'onboarding_location_allow'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _finish(context, granted: false),
                    child: Text('onboarding_location_skip'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
