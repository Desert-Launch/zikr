import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Maps a home-screen widget tap to a screen.
///
/// Both widgets launch the app with `zikr://<host>?homeWidget` — the query
/// flag is what the plugin keys on to recognise the URL as its own on iOS.
/// The host names the destination, so a future widget (a khatma one, say)
/// only has to add a case here.
///
/// Same shape as [NotificationRouter]: one class, one switch, a home fallback
/// for anything unrecognised.
class HomeWidgetRouter {
  HomeWidgetRouter();
  static const String prayerHost = 'prayer';

  static const String _tag = 'HomeWidgetRouter';

  StreamSubscription<Uri?>? _clicks;

  /// Routes the launch that opened the app (if a widget did), then keeps
  /// routing taps that arrive while it is running. Idempotent.
  Future<void> start() async {
    if (_clicks != null) return;
    _clicks = HomeWidget.widgetClicked.listen(
      _route,
      onError: (Object e) =>
          AppLogger.warning('Widget click stream error: $e', tag: _tag),
    );
    try {
      _route(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } catch (e) {
      // No plugin on this platform/engine — nothing to route.
      AppLogger.debug('Widget launch check skipped: $e', tag: _tag);
    }
  }

  Future<void> stop() async {
    await _clicks?.cancel();
    _clicks = null;
  }

  /// Routes after the current frame, as the notification router does, so a
  /// cold-start tap lands once the Modular navigator exists.
  void _route(Uri? uri) {
    if (uri == null) return;
    AppLogger.info('Widget tapped: $uri', tag: _tag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (uri.host) {
        case prayerHost:
          Modular.to.navigate(RoutesNames.prayerBase);
        default:
          Modular.to.navigate(RoutesNames.homeBase);
      }
    });
  }
}
