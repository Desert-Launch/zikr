import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/mosques/data/datasources/remote/ds_remote_mosques.dart';
import 'package:quran/modules/mosques/data/repos/r_impl_mosques.dart';
import 'package:quran/modules/mosques/domain/repos/r_mosques.dart';
import 'package:quran/modules/mosques/domain/usecases/uc_get_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/cubits/cb_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/screens/sn_nearby_mosques.dart';
import 'package:quran/modules/mosques/services/maps_sdk.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';

/// Nearby mosques, looked up through the Google Places API (New) around the
/// reader's location. The remote owns its own Dio → no BaseDio dependency.
class MosquesModule extends Module {
  @override
  void binds(Injector i) {
    // Data source.
    i.add<DSRemoteMosques>(DSRemoteMosques.new);

    // Repo (interface → impl).
    i.add<RMosques>(() => RImplMosques(remote: i.get<DSRemoteMosques>()));

    // Use case.
    i.add(() => UCGetNearbyMosques(i.get<RMosques>()));

    // Native Maps SDK bridge.
    i.add<MapsSdk>(MapsSdk.new);

    // Per-screen cubit. DSLocation and DSLastLocation are AppModule singletons
    // and must be read through `Modular.get` — the local injector does not
    // traverse up into AppModule's binds (see PrayerModule).
    i.add<CBNearbyMosques>(
      () => CBNearbyMosques(
        location: Modular.get<DSLocation>(),
        lastLocation: Modular.get<DSLastLocation>(),
        getNearby: i.get<UCGetNearbyMosques>(),
        mapsSdk: i.get<MapsSdk>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(MosquesRoutes.nearby, child: (_) => const SNNearbyMosques());
  }
}
