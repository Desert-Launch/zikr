import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/adhan/presentation/screens/sn_adhan_picker.dart';
import 'package:quran/modules/adhan/presentation/screens/sn_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/screens/sn_prayer_settings_overview.dart';

/// Screen routes for the adhan feature. CBAdhanPlayer, CBAdhanDownload,
/// CBAdhanSettings + their dependencies are registered as app-wide singletons
/// in AppModule because the prayer-notification handler fires playback before
/// this submodule is mounted.
class AdhanModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const SNPrayerSettingsOverview());
    r.child(AdhanRoutes.notifications, child: (_) => const SNAdhanSettings());
    r.child(AdhanRoutes.picker, child: (_) => SNAdhanPicker(prayerKey: Modular.args.queryParams['prayer'] ?? 'fajr'));
  }
}
