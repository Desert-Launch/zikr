import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

/// Watches the accelerometer while the adhan plays in-app and reports the
/// moment the phone is turned face-down, so playback can be silenced exactly as
/// the Stop button silences it.
///
/// Deliberately mirrors the Kotlin detector in `AdhanPlaybackService` — same
/// thresholds, same arming rule, same hold — so the gesture feels identical
/// whether the adhan is coming from the native prayer-time service or from the
/// in-app ringing screen. Change one, change the other.
class AdhanFlipSilencer {
  /// Z (m/s²) at or below which the device counts as screen-down. Z reads about
  /// +9.8 with the screen up, 0 on edge, and about -9.8 with the screen down.
  static const double faceDownZ = -8.0;

  /// Z at or above which the gesture re-arms — roughly on edge or higher.
  ///
  /// Far from [faceDownZ] on purpose: the band between the two changes nothing,
  /// so a phone resting near the boundary, or wobbling as it is set down, can't
  /// flicker between the two states.
  static const double faceUpZ = -4.0;

  /// How long the device must stay face-down before the adhan is cut. Long
  /// enough that brushing past that angle while picking the phone up cannot
  /// stop the call to prayer by accident.
  static const Duration faceDownHold = Duration(milliseconds: 700);

  StreamSubscription<AccelerometerEvent>? _sub;

  /// True once the device has been seen NOT face-down since watching began.
  ///
  /// Turning the phone over is the gesture; *already lying* face-down is not.
  /// Without this, a phone left screen-down on a desk would silence the adhan
  /// the instant it started.
  bool _armed = false;

  DateTime? _faceDownSince;

  bool get isWatching => _sub != null;

  /// Starts watching. [onFaceDown] fires once, after which watching stops —
  /// call [start] again for the next adhan.
  void start(void Function() onFaceDown) {
    stop();
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(
          (event) => _onSample(event.z, onFaceDown),
          // A device with no accelerometer (or one that refuses the stream)
          // simply keeps the on-screen Stop button.
          onError: (Object _) => stop(),
          cancelOnError: true,
        );
  }

  void _onSample(double z, void Function() onFaceDown) {
    if (z >= faceUpZ) {
      _armed = true;
      _faceDownSince = null;
      return;
    }
    if (z > faceDownZ) return;
    if (!_armed) return;

    final since = _faceDownSince;
    final now = DateTime.now();
    if (since == null) {
      _faceDownSince = now;
      return;
    }
    if (now.difference(since) >= faceDownHold) {
      stop();
      onFaceDown();
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _armed = false;
    _faceDownSince = null;
  }
}
