import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/adhan/presentation/screens/sn_adhan_picker.dart';

/// Just the screen route. CBAdhanPlayer + its dependencies are registered as
/// app-wide singletons in AppModule because the prayer-notification handler
/// fires playback before this submodule is mounted.
class AdhanModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const SNAdhanPicker());
  }
}
