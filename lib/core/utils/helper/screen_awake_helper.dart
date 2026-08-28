import 'dart:async';

import 'package:quran/core/services/logging/app_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Single owner of the "keep the display on" flag.
///
/// The device's own screen timeout is right almost everywhere in the app, but
/// not while the mushaf is open: reading a page takes longer than the timeout,
/// and the screen going dark mid-ayah is the one interruption a reader cannot
/// work around without touching the glass.
///
/// Screens [request] a hold while they are on screen and [release] it when they
/// leave, exactly like [OrientationHelper]. Holds are counted, so two screens
/// asking at once cannot switch each other off — the display stays lit until
/// the last hold is given back.
class ScreenAwakeHelper {
  ScreenAwakeHelper._();

  /// Live holds. The flag is on for as long as this is not empty.
  static final List<ScreenAwakeHold> _holds = <ScreenAwakeHold>[];

  /// Whether the display is being held awake right now.
  static bool get isHeld => _holds.isNotEmpty;

  /// Keep the display on until the returned token is handed to [release].
  static ScreenAwakeHold request() {
    final hold = ScreenAwakeHold._();
    _holds.add(hold);
    unawaited(_apply());
    return hold;
  }

  /// Drop [hold]. Safe to call twice and safe to call out of order — holds are
  /// matched by identity rather than popped off the end.
  static void release(ScreenAwakeHold hold) {
    if (!_holds.remove(hold)) return;
    unawaited(_apply());
  }

  /// Pushes the current state to the platform.
  ///
  /// Failures are logged and swallowed: the wakelock is a comfort, never a
  /// requirement, and a plugin that is missing (an app running from before this
  /// dependency was added) must not take the reader down with it.
  static Future<void> _apply() async {
    try {
      await WakelockPlus.toggle(enable: isHeld);
    } catch (e) {
      AppLogger.warning('Wakelock toggle failed: $e', tag: 'ScreenAwake');
    }
  }
}

/// A screen's claim on the display staying lit. Opaque on purpose: the only
/// thing to do with one is hand it back to [ScreenAwakeHelper.release].
class ScreenAwakeHold {
  ScreenAwakeHold._();
}
