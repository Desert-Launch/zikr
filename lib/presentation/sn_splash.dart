import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Boot screen. Shows the branded splash image for ~1s, then opens onboarding
/// on first install, otherwise the guest-friendly home screen. Authentication
/// is requested only when a protected feature is opened.
class SNSplash extends StatefulWidget {
  const SNSplash({super.key});

  @override
  State<SNSplash> createState() => _SNSplashState();
}

class _SNSplashState extends State<SNSplash> {
  /// Brand green — matches the native splash so the hand-off is seamless.
  static const Color _bg = Color(0xFF0D7E5E);

  @override
  void initState() {
    super.initState();
    unawaited(_routeWhenReady());
  }

  Future<void> _routeWhenReady() async {
    // Hold the splash image on screen for one second before routing.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final settings = Modular.get<BoxAppSettings>().current();
    final target = settings.hasSeenOnboarding
        ? RoutesNames.homeBase
        : RoutesNames.onboardingBase;
    Modular.to.navigate(target);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/splash_screen.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
