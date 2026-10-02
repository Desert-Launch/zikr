import 'dart:async';

import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/app_audio_handler.dart';
import 'package:quran/core/services/media/media_session_binding.dart';

/// Coordinates the single app-wide media-playback slot.
///
/// The app has one media session ([AppAudioHandler]) — one notification, one
/// lock-screen card, one entry in the car — so only one domain player should
/// sound at a time. Every domain player (Qur'an audio, radio, adhan, azkar,
/// salawat and reciter previews) is a background singleton, so several can be
/// alive at once. This coordinator makes them mutually exclusive: a player
/// calls [take] right before loading a new source, which stops whichever other
/// player currently holds the slot so it is free by the time the caller loads,
/// and points the media session at the caller's player.
///
/// A player releases the slot when it is **stopped** — pausing or merely
/// navigating away does not.
class AudioFocus {
  AudioFocus._();

  /// Global instance — the media slot is a single hardware-like resource shared
  /// across feature modules, so a plain singleton (not per-module DI) fits.
  static final AudioFocus instance = AudioFocus._();

  Object? _holder;
  final Map<Object, Future<void> Function()> _stoppers =
      <Object, Future<void> Function()>{};
  final Map<Object, MediaSessionBinding> _sessions =
      <Object, MediaSessionBinding>{};

  /// Registers [owner]'s stop callback. Call once when the player is created.
  ///
  /// [session] puts the owner's player on the media session (notification,
  /// lock screen, headset buttons, car) while it holds focus. Without one the
  /// owner plays with no session controls at all — fine for a few-second
  /// preview.
  void register(
    Object owner,
    Future<void> Function() stop, {
    MediaSessionBinding? session,
  }) {
    _stoppers[owner] = stop;
    if (session != null) {
      _sessions[owner] = session;
    } else {
      _sessions.remove(owner);
    }
  }

  /// Drops [owner]'s registration. Call from the owner's `close`.
  void unregister(Object owner) {
    release(owner);
    _stoppers.remove(owner);
    _sessions.remove(owner);
  }

  /// [owner] is about to load a new audio source. Stops the current holder (when
  /// it is a different player) so the shared slot is free, then records [owner]
  /// as the new holder. Awaited so the previous platform is fully released
  /// before the caller loads.
  ///
  /// The session is handed to [owner] *before* the previous holder stops, so
  /// that stop is not mirrored as the session ending — on Android that would
  /// tear down the notification and the car's now-playing screen only for them
  /// to come straight back.
  Future<void> take(Object owner) async {
    final prev = _holder;
    _holder = owner;
    AppAudioHandler.instance?.bind(owner, _sessions[owner]);
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
  }

  /// [owner] gave up the slot on its own (stopped/finished). Clears the holder
  /// — and the media session — only if it still points at [owner].
  void release(Object owner) {
    if (!identical(_holder, owner)) return;
    _holder = null;
    AppAudioHandler.instance?.unbind(owner);
  }
}
