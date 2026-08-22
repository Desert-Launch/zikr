import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Single owner of the app's preferred device orientations.
///
/// The app is portrait-locked, but a couple of screens read better in
/// landscape (the mushaf reader, the live broadcast). They used to call
/// [SystemChrome.setPreferredOrientations] directly and restore portrait in
/// `dispose`, which left two gaps: the lock was never reapplied if the OS
/// dropped it while the app was backgrounded, and a blind restore on resume
/// would have yanked an open reader back to portrait.
///
/// So the wanted orientation lives here instead. Screens [request] a set on
/// entry and [release] it on exit; [reapply] re-asserts whatever is wanted
/// *right now* — portrait when nothing is overriding it.
///
/// Screens should not hold an override by hand — use [OrientationOverrideRoute],
/// which also hands it back while the screen is covered by another one.
class OrientationHelper {
  OrientationHelper._();

  /// The app-wide default: portrait both ways up.
  static const portrait = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  /// Portrait *and* landscape — for screens that rotate with the device.
  static const free = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Landscape only — for screens that are unusable upright.
  static const landscape = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Active overrides, oldest first. The last one wins, so a screen pushed on
  /// top of another override takes over and hands control back on release.
  static final List<OrientationOverride> _overrides = <OrientationOverride>[];

  /// What the app wants on screen at this moment.
  static List<DeviceOrientation> get current =>
      _overrides.isEmpty ? portrait : _overrides.last.orientations;

  /// Override the portrait lock for as long as the caller is on screen. Keep
  /// the returned token and pass it to [release] in `dispose`.
  static OrientationOverride request(List<DeviceOrientation> orientations) {
    final override = OrientationOverride._(orientations);
    _overrides.add(override);
    unawaited(reapply());
    return override;
  }

  /// Drop [override] and re-assert whatever is left.
  ///
  /// Safe to call twice, and safe to call out of order: overrides are matched
  /// by identity rather than popped off the end.
  static void release(OrientationOverride override) {
    if (!_overrides.remove(override)) return;
    unawaited(reapply());
  }

  /// Re-assert the current preference. Called on resume — the engine can come
  /// back from the background without the lock the app last set, and a screen
  /// torn down while hidden has no `dispose` left to run.
  static Future<void> reapply() =>
      SystemChrome.setPreferredOrientations(current);
}

/// A screen's claim on the device orientation. Opaque on purpose: the only
/// thing to do with one is hand it back to [OrientationHelper.release].
class OrientationOverride {
  OrientationOverride._(this.orientations);

  final List<DeviceOrientation> orientations;
}

/// Watches pushes and pops so a screen can be told when it stops being — and
/// becomes again — the one the user is looking at.
///
/// Registered alongside the app's other navigator observer in `main()`. Typed
/// to `PageRoute` on purpose: a bottom sheet or a dialog is a [PopupRoute], and
/// opening one over the reader should not count as leaving it.
final RouteObserver<PageRoute<dynamic>> appRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Holds an [OrientationHelper] override for exactly as long as the screen is
/// the visible one.
///
/// Requesting in `initState` and releasing in `dispose` is not the same thing.
/// A screen pushed ON TOP of the reader — tafsir, the reciter picker, the
/// reader's own settings — leaves the reader alive and undisposed, so its
/// override stayed active and those screens inherited a rotation they never
/// asked for. This gives the override back when the screen is covered and takes
/// it again when it is uncovered, so the orientation follows what is actually
/// on screen.
mixin OrientationOverrideRoute<T extends StatefulWidget> on State<T> implements RouteAware {
  /// What this screen wants while it is the visible one — one of
  /// [OrientationHelper.free], [OrientationHelper.landscape], etc.
  List<DeviceOrientation> get orientations;

  OrientationOverride? _override;

  void _claim() {
    if (_override != null) return;
    _override = OrientationHelper.request(orientations);
  }

  void _surrender() {
    final override = _override;
    if (override == null) return;
    OrientationHelper.release(override);
    _override = null;
  }

  @override
  void initState() {
    super.initState();
    // Not [didPush]: the subscription below is only made once this screen has
    // been built, by which point its own push has already been announced.
    _claim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _surrender();
    super.dispose();
  }

  /// Already claimed in [initState] — see the note there.
  @override
  void didPush() {}

  @override
  void didPop() => _surrender();

  /// Covered by another screen: still alive, no longer being read.
  @override
  void didPushNext() => _surrender();

  /// Uncovered again — whatever was on top of this screen has popped.
  @override
  void didPopNext() => _claim();
}
