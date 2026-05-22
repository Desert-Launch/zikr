import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/domain/entities/e_auth_status.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';

/// Boot screen. Decides between onboarding / auth / home using:
/// 1. `BoxAppSettings.hasSeenOnboarding` — false on first install.
/// 2. `CBAuth.state.isLoggedIn` — true if a valid token is in the box.
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

    // Wait briefly for CBAuth.bootstrap() (started in main) to settle.
    final cb = Modular.get<CBAuth>();
    final start = DateTime.now();
    while (cb.state.status == EAuthStatus.unknown &&
        DateTime.now().difference(start) < const Duration(milliseconds: 1500)) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    Modular.to.navigate(
      cb.state.isLoggedIn ? RoutesNames.homeBase : RoutesNames.authBase,
    );
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
            Icon(Icons.menu_book_rounded,
                size: 96.r, color: AppColorsLight.primary),
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
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
