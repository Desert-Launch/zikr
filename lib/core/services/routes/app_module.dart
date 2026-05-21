import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/theme_manager.dart';
import 'package:quran/modules/quran/quran_module.dart';
import 'package:quran/presentation/sn_splash.dart';

/// Root [Module] that wires the splash screen and mounts the Quran module.
class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ThemeManager>(ThemeManager.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      RoutesNames.splash,
      transition: TransitionType.fadeIn,
      child: (_) => const SNSplash(),
    );
    r.module(RoutesNames.quranBase, module: QuranModule());
  }
}

/// Simple modular observer for navigation logging.
class AppModularObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('[Nav] PUSH ${route.settings.name} (from: ${previousRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('[Nav] POP ${route.settings.name} → ${previousRoute?.settings.name}');
  }
}
