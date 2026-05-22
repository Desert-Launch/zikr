import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_times.dart';

/// Just the screen routes for the prayer times feature. All shared
/// dependencies (DSLocation, BoxPrayerCache, BoxPrayerSettings,
/// CBPrayerTimes) are registered in AppModule so Home and Notifications
/// can read them before this module mounts.
class PrayerModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const SNPrayerTimes());
  }
}
