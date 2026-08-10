import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:vibration/vibration.dart';

/// Tactile feedback for counter-style screens (tasbih, salawat).
///
/// Two channels are fired for every buzz, because either one alone can be
/// silently swallowed:
/// * the vibration motor — the plugin tags it `USAGE_ALARM`, so it survives
///   the system "touch vibration" setting being off;
/// * [HapticFeedback] — the only channel on devices whose motor the platform
///   doesn't expose, and the better citizen on iOS. On plenty of Android
///   devices it produces nothing at all, so it is a backstop, not a guarantee.
///
/// Neither call throws on a device that can't honour it, so firing both is
/// safe; a device that supports both produces one buzz, not two.
abstract final class HapticsHelper {
  static const _tag = 'HapticsHelper';

  /// Tick on a motor with amplitude control: brief, and well under full power,
  /// so a count registers as a light tap rather than a buzz. Amplitude is the
  /// honest way to soften a tick — the motor still starts instantly, it just
  /// doesn't drive as hard.
  static const _tickMs = 40;
  static const _tickAmplitude = 110;

  /// Tick without amplitude control. The plugin drops the requested amplitude
  /// and runs the motor flat out at `DEFAULT_AMPLITUDE`, so length is the only
  /// lever: shorter is the only way to make it softer. Not shorter still,
  /// because the rotational motors that report this way spend tens of
  /// milliseconds spinning up and a shorter pulse ends before it is felt.
  static const _tickMsNoAmplitude = 55;

  /// Device capabilities, resolved once and cached. Logged on first resolve so
  /// a "nothing happens" report can be traced to a device with no motor.
  static bool? _hasVibrator;
  static bool? _hasAmplitudeControl;

  /// Resolves the capability checks ahead of the first tap so the buzz isn't
  /// delayed by a platform-channel round trip. Safe to call repeatedly.
  static Future<void> prepare() => _resolve();

  static Future<void> _resolve() async {
    if (_hasVibrator != null) return;
    try {
      final has = await Vibration.hasVibrator();
      final amplitude = has && await Vibration.hasAmplitudeControl();
      _hasVibrator = has;
      _hasAmplitudeControl = amplitude;
      AppLogger.info(
        'hasVibrator=$has amplitudeControl=$amplitude',
        tag: _tag,
      );
    } catch (e, st) {
      AppLogger.error('vibrator capability check failed',
          error: e, stackTrace: st, tag: _tag);
      _hasVibrator = false;
      _hasAmplitudeControl = false;
    }
  }

  /// Light tap for a single counter increment.
  static Future<void> tick() async {
    // Only shapes the pulse — never gates the buzz itself, so a device that
    // under-reports its motor still gets the (safer, duration-only) tick.
    await _resolve();
    final hasAmplitude = _hasAmplitudeControl ?? false;
    await _buzz(
      motor: () => Vibration.vibrate(
        duration: hasAmplitude ? _tickMs : _tickMsNoAmplitude,
        amplitude: hasAmplitude ? _tickAmplitude : 255,
      ),
      fallback: HapticFeedback.lightImpact,
    );
  }

  /// Distinct double-tap when a target is reached — the one moment worth
  /// interrupting for, so it stays firmer than [tick], but kept in proportion
  /// to it rather than the half-second buzz it used to be.
  static Future<void> complete() => _buzz(
        motor: () => Vibration.vibrate(pattern: const [0, 90, 70, 110]),
        fallback: HapticFeedback.mediumImpact,
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
