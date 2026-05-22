import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/khatma/presentation/screens/sn_khatma_completed.dart';
import 'package:quran/modules/khatma/presentation/screens/sn_khatma_history.dart';
import 'package:quran/modules/khatma/presentation/screens/sn_khatma_plans.dart';
import 'package:quran/modules/khatma/presentation/screens/sn_khatma_tracker.dart';

class KhatmaModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child(KhatmaRoutes.plans, child: (_) => const SNKhatmaPlans());
    r.child(KhatmaRoutes.tracker, child: (_) => const SNKhatmaTracker());
    r.child(KhatmaRoutes.completed, child: (_) => const SNKhatmaCompleted());
    r.child(KhatmaRoutes.history, child: (_) => const SNKhatmaHistory());
  }
}
