import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Boot screen. A plain green surface — the same brand green as the native
/// splash, so the hand-off is invisible — that routes to onboarding on first
/// install and to the guest-friendly home screen otherwise. Authentication is
/// requested only when a protected feature is opened.
///
/// Nothing is drawn and nothing is awaited: this screen exists only to read
/// [BoxAppSettings] and pick a destination, so it should be on screen for a
/// single frame.
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
    // Post-frame, not inline: navigating while this widget is still building
    // tears down the route that is mid-build. One frame is also all it takes
    // for the green to be painted, so there's no white flash on the way out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  void _route() {
    if (!mounted) return;
    final settings = Modular.get<BoxAppSettings>().current();
    final target = settings.hasSeenOnboarding
        ? RoutesNames.homeBase
        : RoutesNames.onboardingBase;
    Modular.to.navigate(target);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: _bg);
}
