import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/settings/presentation/screens/sn_contact_us.dart';
import 'package:quran/modules/settings/presentation/screens/sn_rate_app.dart';
import 'package:quran/modules/settings/presentation/screens/sn_settings.dart';
import 'package:quran/modules/settings/presentation/screens/sn_share_app.dart';

class SettingsModule extends Module {
  @override
  void binds(Injector i) {
    // No module-local bindings — settings reads app-wide singletons (CBAuth,
    // CBTheme, BoxThemePref) registered in AppModule.
  }

  @override
  void routes(RouteManager r) {
    r.child(SettingsRoutes.main, child: (_) => const SNSettings());
    r.child(SettingsRoutes.contact, child: (_) => const SNContactUs());
    r.child(SettingsRoutes.share, child: (_) => const SNShareApp());
    r.child(SettingsRoutes.rate, child: (_) => const SNRateApp());
  }
}
