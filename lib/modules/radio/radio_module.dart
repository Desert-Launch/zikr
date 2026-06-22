import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/radio/data/datasources/local/ds_local_radio.dart';
import 'package:quran/modules/radio/data/datasources/remote/ds_remote_radio.dart';
import 'package:quran/modules/radio/data/repos/r_impl_radio.dart';
import 'package:quran/modules/radio/domain/repos/r_radio.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_live_stations.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_national_stations.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio.dart';
import 'package:quran/modules/radio/presentation/screens/sn_radio.dart';

/// Quran radio module. The live player ([CBRadioPlayer]) is an app-wide
/// singleton registered in [AppModule] so playback survives leaving this module;
/// everything below is scoped to the radio routes.
class RadioModule extends Module {
  @override
  void binds(Injector i) {
    // Data sources (remote owns its own Dio → no BaseDio dependency).
    i.add<DSLocalRadio>(DSLocalRadio.new);
    i.add<DSRemoteRadio>(DSRemoteRadio.new);

    // Repo (interface → impl).
    i.add<RRadio>(
      () => RImplRadio(local: i.get<DSLocalRadio>(), remote: i.get<DSRemoteRadio>()),
    );

    // Use cases.
    i.add(() => UCGetNationalStations(i.get<RRadio>()));
    i.add(() => UCGetLiveStations(i.get<RRadio>()));

    // Per-screen cubit.
    i.add<CBRadio>(
      () => CBRadio(
        getNational: i.get<UCGetNationalStations>(),
        getLive: i.get<UCGetLiveStations>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(RadioRoutes.home, child: (_) => const SNRadio());
  }
}
