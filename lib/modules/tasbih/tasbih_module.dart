import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/tasbih/presentation/screens/sn_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/screens/sn_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/screens/sn_tasbih_hourly.dart';

class TasbihModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(TasbihRoutes.counter, child: (_) => const SNTasbih());
    r.child(TasbihRoutes.history, child: (_) => const SNTasbihHistory());
    r.child(TasbihRoutes.hourly, child: (_) => const SNTasbihHourly());
  }
}
