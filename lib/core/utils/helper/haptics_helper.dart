import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:vibration/vibration.dart';

/// Tactile feedback for counter-style screens (tasbih, salawat).
///
/// Two independent channels are fired for every buzz, because either one
/// alone can be silently swallowed:
/// * the vibration motor — the plugin tags it `USAGE_ALARM`, so it survives
///   the system "touch vibration" setting being off;
/// * [HapticFeedback] — the only channel on devices whose motor the platform
///   doesn't expose, and the better citizen on iOS.
///
/// Neither call throws on a device that can't honour it, so firing both is
/// safe; a device that supports both produces one buzz, not two.
abstract final class HapticsHelper {
  static const _tag = 'HapticsHelper';

  /// Motor support, resolved once and cached. Logged on first resolve so a
  /// "nothing happens" report can be traced to a device with no motor.
  static bool? _hasVibrator;

  /// Resolves the motor check ahead of the first tap so the buzz isn't
  /// delayed by a platform-channel round trip. Safe to call repeatedly.
  static Future<void> prepare() => _resolve();

  static Future<bool> _resolve() async {
    final cached = _hasVibrator;
    if (cached != null) return cached;
    try {
      final has = await Vibration.hasVibrator();
      AppLogger.info('hasVibrator=$has', tag: _tag);
      return _hasVibrator = has;
    } catch (e, st) {
      AppLogger.error('hasVibrator check failed',
          error: e, stackTrace: st, tag: _tag);
      return _hasVibrator = false;
    }
  }

  /// Short, firm buzz for a single counter increment.
  static Future<void> tick() => _buzz(
        motor: () => Vibration.vibrate(duration: 60, amplitude: 255),
        fallback: HapticFeedback.mediumImpact,
      );

  /// Distinct double-buzz when a target is reached.
  static Future<void> complete() => _buzz(
        motor: () => Vibration.vibrate(pattern: const [0, 200, 100, 300]),
        fallback: HapticFeedback.heavyImpact,
      );

  static Future<void> _buzz({
    required Future<void> Function() motor,
    required Future<void> Function() fallback,
  }) async {
    // Not gated on [_resolve]: a device that under-reports its motor would
    // otherwise never buzz. The plugin's native side already no-ops when
    // there is genuinely no vibrator.
    try {
      await motor();
    } catch (e, st) {
      AppLogger.error('motor vibrate failed', error: e, stackTrace: st, tag: _tag);
    }
    try {
      await fallback();
    } catch (e, st) {
      AppLogger.error('haptic fallback failed', error: e, stackTrace: st, tag: _tag);
    }
  }
}
