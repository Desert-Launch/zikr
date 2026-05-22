import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/home/presentation/screens/sn_home.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
    // Home reads from app-wide singletons (CBAuth) — no local bindings yet.
  }

  @override
  void routes(RouteManager r) {
    r.child(HomeRoutes.dashboard, child: (_) => const SNHome());
  }
}
