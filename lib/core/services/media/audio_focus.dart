import 'dart:async';

import 'package:quran/core/services/logging/app_logger.dart';

/// Coordinates the single app-wide media-playback slot.
///
/// `just_audio_background` (initialised in `main`) permits only ONE
/// platform-active `AudioPlayer` at a time: the first player to load a source
/// claims the slot, and a second player's `setAudioSource` throws
/// *"just_audio_background supports only a single player instance"*. A player
/// releases the slot when it is **stopped** (`AudioPlayer.stop()` deactivates
/// its platform) — pausing or merely navigating away does not.
///
/// Every domain player (Qur'an audio, radio, adhan, reciter preview) is a
/// background singleton, so several can be alive at once. This coordinator makes
/// them mutually exclusive: a player calls [take] right before loading a new
/// source, which stops whichever other player currently holds the slot so it is
/// free by the time the caller loads.
class AudioFocus {
  AudioFocus._();

  /// Global instance — the media slot is a single hardware-like resource shared
  /// across feature modules, so a plain singleton (not per-module DI) fits.
  static final AudioFocus instance = AudioFocus._();

  Object? _holder;
  final Map<Object, Future<void> Function()> _stoppers =
      <Object, Future<void> Function()>{};

  /// Registers [owner]'s stop callback. Call once when the player is created.
  void register(Object owner, Future<void> Function() stop) {
    _stoppers[owner] = stop;
  }

  /// Drops [owner]'s registration. Call from the owner's `close`.
  void unregister(Object owner) {
    _stoppers.remove(owner);
    release(owner);
  }

  /// [owner] is about to load a new audio source. Stops the current holder (when
  /// it is a different player) so the shared slot is free, then records [owner]
  /// as the new holder. Awaited so the previous platform is fully released
  /// before the caller loads.
  Future<void> take(Object owner) async {
    final prev = _holder;
    if (prev != null && !identical(prev, owner)) {
      final stop = _stoppers[prev];
      if (stop != null) {
        try {
          await stop();
        } catch (e) {
          AppLogger.warning('AudioFocus stop failed: $e', tag: 'AudioFocus');
        }
      }
    }
    _holder = owner;
  }

  /// [owner] gave up the slot on its own (stopped/finished). Clears the holder
  /// only if it still points at [owner].
  void release(Object owner) {
    if (identical(_holder, owner)) _holder = null;
  }
}
