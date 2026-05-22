import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/qibla/presentation/screens/sn_qibla.dart';

class QiblaModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(QiblaRoutes.compass, child: (_) => const SNQibla());
  }
}
