import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/live/presentation/screens/sn_live.dart';

/// Haramain live-broadcast module. Purely presentational — it embeds the
/// official KSA YouTube channels (see [ELiveChannel]); there is no data layer.
class LiveModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(LiveRoutes.home, child: (_) => const SNLive());
  }
}
