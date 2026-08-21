import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Navigation fallbacks for screens that can be opened with an empty history.
///
/// Tapping a notification while the app is killed hands the user a screen that
/// is the *only* route in the stack. A plain `Modular.to.pop()` there pops the
/// last route and leaves a black window with nothing under it, so every back
/// affordance goes through [back] instead: pop when there is somewhere to go
/// back to, otherwise land on Home.
class NavHelper {
  NavHelper._();

  /// Whether the current route has something beneath it in the stack.
  static bool get canPop => Modular.to.canPop();

  /// Back button behaviour: pop, or fall back to Home on an empty stack.
  static void back<T extends Object?>([T? result]) {
    if (Modular.to.canPop()) {
      Modular.to.pop(result);
    } else {
      goHome();
    }
  }

  /// Resets the stack to the Home dashboard.
  static void goHome() => Modular.to.navigate(RoutesNames.homeBase);
}
