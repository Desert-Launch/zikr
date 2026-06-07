import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Boot screen. Shows onboarding on first install, then opens the guest-friendly
/// home screen. Authentication is requested only when a protected feature is
/// opened.
class SNSplash extends StatefulWidget {
  const SNSplash({super.key});

  @override
  State<SNSplash> createState() => _SNSplashState();
}

class _SNSplashState extends State<SNSplash> {
  @override
  void initState() {
    super.initState();
    unawaited(_routeWhenReady());
  }

  Future<void> _routeWhenReady() async {
    // First-run check — no auth state needed.
    final settings = Modular.get<BoxAppSettings>().current();
    if (!settings.hasSeenOnboarding) {
      Modular.to.navigate(RoutesNames.onboardingBase);
      return;
    }

    if (!mounted) return;
    Modular.to.navigate(RoutesNames.homeBase);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 96.r,
              color: AppColorsLight.primary,
            ),
            SizedBox(height: 24.h),
            Text(
              'القرآن الكريم',
              style: GoogleFonts.amiri(
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
                color: AppColorsLight.primaryDark,
              ),
            ),
            SizedBox(height: 32.h),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
