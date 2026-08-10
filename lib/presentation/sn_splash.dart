import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Boot screen. Shows the brand artwork on the same [_bg] green as the native
/// splash — so the native → Flutter hand-off is invisible — then routes to
/// onboarding on first install and to the guest-friendly home screen otherwise.
/// Authentication is requested only when a protected feature is opened.
///
/// Nothing is awaited: this screen only reads [BoxAppSettings] and picks a
/// destination. It is held on screen for [_minVisible] purely so the artwork is
/// actually seen rather than flashing for a single frame.
class SNSplash extends StatefulWidget {
  const SNSplash({super.key});

  @override
  State<SNSplash> createState() => _SNSplashState();
}

class _SNSplashState extends State<SNSplash> {
  /// Brand green — matches the native splash so the hand-off is seamless, and
  /// matches the artwork's own background so its rounded corners blend in.
  static const Color _bg = Color(0xFF085B43);

  /// How long the artwork stays on screen before routing away.
  static const Duration _minVisible = Duration(milliseconds: 1800);

  /// Fade-in for the artwork, so it emerges from the flat native-splash green
  /// instead of popping in.
  static const Duration _fadeIn = Duration(milliseconds: 500);

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Post-frame, not inline: navigating (or calling setState) while this widget
    // is still building tears down the route that is mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      Future<void>.delayed(_minVisible, _route);
    });
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: _fadeIn,
      curve: Curves.easeOut,
      // cover, not contain: the artwork is a full-bleed green field with a
      // centred logo, so cropping the edges on a different aspect ratio (a
      // tablet) is invisible, while contain would letterbox it.
      child: Image.asset(
        Assets.images.splashScreen.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
