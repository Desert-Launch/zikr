import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_times.dart';

/// Screen routes for the prayer feature.
///
/// The shared dependencies (DSLocation, BoxPrayerSettings, PrayerTimesService,
/// CBPrayerTimes) live in AppModule so Home and the notification schedulers can
/// read them before this module mounts.
class PrayerModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(PrayerRoutes.times, child: (_) => const SNPrayerTimes());
  }
}
