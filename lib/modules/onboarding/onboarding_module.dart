import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/onboarding/presentation/cubits/cb_onboarding.dart';
import 'package:quran/modules/onboarding/presentation/screens/sn_language_selection.dart';
import 'package:quran/modules/onboarding/presentation/screens/sn_location_permission.dart';
import 'package:quran/modules/onboarding/presentation/screens/sn_onboarding_pager.dart';

class OnboardingModule extends Module {
  @override
  void binds(Injector i) {
    // CBOnboarding is shared across the 3 onboarding screens, so register
    // it as a singleton scoped to the onboarding module's lifetime.
    i.addSingleton<CBOnboarding>(
      () => CBOnboarding(
        Modular.get<BoxAppSettings>(),
        Modular.get<NotificationsService>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(OnboardingRoutes.pager, child: (_) => const SNOnboardingPager());
    r.child(OnboardingRoutes.language, child: (_) => const SNLanguageSelection());
    r.child(OnboardingRoutes.location, child: (_) => const SNLocationPermission());
  }
}
