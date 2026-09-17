import 'dart:async';

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
///
/// Pulses are never allowed to pile up. Firing a fresh one-shot into the
/// vibrator service while the last is still running — what a fast tapper does
/// twenty times a second — leaves some motors (Samsung, notably) buzzing with
/// the off command never honoured, and nothing in the app would ever stop it.
/// So a tick that lands mid-pulse is dropped, and a watchdog sends an explicit
/// cancel once the last pulse should be over.
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

  /// The finish of [complete]'s waveform: 90 on, 70 off, 110 on.
  static const _completePattern = [0, 90, 70, 110];
  static const _completeMs = 270;

  /// Device capabilities, resolved once and cached. Logged on first resolve so
  /// a "nothing happens" report can be traced to a device with no motor.
  static bool? _hasVibrator;
  static bool? _hasAmplitudeControl;

  /// When the pulse in flight is due to end. A tick arriving before then is
  /// dropped — at that tap rate the pulses would only merge into one buzz.
  static DateTime? _busyUntil;

  /// Explicit stop for a motor that missed its own off. Re-armed by every
  /// pulse, so it fires once after the last one and never cuts one short.
  static Timer? _watchdog;
  static const _watchdogSlack = Duration(milliseconds: 60);

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

  /// Light tap for a single counter increment. Skipped while another pulse
  /// (a tick, or the longer [complete]) is still running.
  static Future<void> tick() async {
    // Only shapes the pulse — never gates the buzz itself, so a device that
    // under-reports its motor still gets the (safer, duration-only) tick.
    await _resolve();
    if (_motorBusy) return;
    final hasAmplitude = _hasAmplitudeControl ?? false;
    final ms = hasAmplitude ? _tickMs : _tickMsNoAmplitude;
    await _buzz(
      length: Duration(milliseconds: ms),
      motor: () => Vibration.vibrate(
        duration: ms,
        amplitude: hasAmplitude ? _tickAmplitude : 255,
      ),
      fallback: HapticFeedback.lightImpact,
    );
  }

  /// Distinct double-tap when a target is reached — the one moment worth
  /// interrupting for, so it stays firmer than [tick], but kept in proportion
  /// to it rather than the half-second buzz it used to be. Never throttled:
  /// it takes over from whatever tick is running.
  static Future<void> complete() => _buzz(
        length: const Duration(milliseconds: _completeMs),
        motor: () => Vibration.vibrate(pattern: _completePattern),
        fallback: HapticFeedback.mediumImpact,
      );

  static bool get _motorBusy {
    final until = _busyUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  static Future<void> _buzz({
    required Duration length,
    required Future<void> Function() motor,
    required Future<void> Function() fallback,
  }) async {
    _busyUntil = DateTime.now().add(length);
    _armWatchdog(length + _watchdogSlack);
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

  static void _armWatchdog(Duration after) {
    _watchdog?.cancel();
    _watchdog = Timer(after, () async {
      _watchdog = null;
      try {
        await Vibration.cancel();
      } catch (e, st) {
        AppLogger.error('motor cancel failed', error: e, stackTrace: st, tag: _tag);
      }
    });
  }
}
