import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_adjustments.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_method_picker.dart';
import 'package:quran/modules/prayer/presentation/screens/sn_prayer_times.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_calculation_methods.dart';

/// Screen routes for the prayer feature.
///
/// The shared dependencies (DSLocation, BoxPrayerSettings, PrayerTimesService,
/// CBPrayerTimes) live in AppModule so Home and the notification schedulers can
/// read them before this module mounts. Only the calculation-settings cubit is
/// registered here — it is scoped to these screens.
class PrayerModule extends Module {
  @override
  void binds(Injector i) {
    // Singleton within this module's scope: the settings screen, the method
    // picker and the adjustments screen are three routes over ONE editing
    // session, and a factory would hand each of them its own copy of the
    // settings — picking a method on one screen would leave the others showing
    // the old one.
    i.addSingleton<CBPrayerCalcSettings>(
      () => CBPrayerCalcSettings(
        box: i.get<BoxPrayerSettings>(),
        getMethods: i.get<UCGetCalculationMethods>(),
        prayerTimes: i.get<CBPrayerTimes>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(PrayerRoutes.times, child: (_) => const SNPrayerTimes());
    r.child(
      PrayerRoutes.calculation,
      child: (_) => const SNPrayerCalcSettings(),
    );
    r.child(
      PrayerRoutes.methodPicker,
      child: (_) => const SNPrayerMethodPicker(),
    );
    r.child(
      PrayerRoutes.adjustments,
      child: (_) => const SNPrayerAdjustments(),
    );
  }
}
