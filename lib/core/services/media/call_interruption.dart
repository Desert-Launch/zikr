import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Tracks whether another app currently owns the audio session — a phone call,
/// in practice — so app-played reminder audio and haptics can hold back.
///
/// **Why audio focus and not call state.** Reading the actual call state needs
/// `READ_PHONE_STATE` on Android, a sensitive permission this app deliberately
/// does not request. Audio-session interruption covers the same cases through
/// an API that needs no grant at all: `audio_session` maps to `AudioManager`
/// audio-focus loss on Android and `AVAudioSession.interruptionNotification` on
/// iOS. It is less precise — a video call, a voice note or another media app
/// taking focus reads the same as a phone call — which is the accepted
/// trade-off for asking the user for nothing.
///
/// **What this can and cannot reach.** It gates audio and haptics the APP
/// plays. It cannot silence an OS-posted notification's channel sound: those
/// are played by the system, usually with this app's process not running at
/// all, and no API lets an app retract a sound already handed to the notifier.
/// Android does attenuate notification-usage sounds during a call on its own —
/// which is the platform's own answer to the same problem, and why routing
/// salawat to an ALARM-usage channel (the "ignore silent" control) makes it
/// *less* likely to be ducked mid-call.
class CallInterruption {
  CallInterruption._();

  static final CallInterruption instance = CallInterruption._();

  StreamSubscription<AudioInterruptionEvent>? _sub;
  bool _interrupted = false;

  /// True while another app holds the audio session.
  bool get isInterrupted => _interrupted;

  /// Starts listening. Safe to call repeatedly; a failure to configure the
  /// session leaves [isInterrupted] permanently false, which degrades to the
  /// pre-existing behaviour rather than muting anything by accident.
  Future<void> start() async {
    if (_sub != null) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _sub = session.interruptionEventStream.listen((event) {
        // `begin` covers both the duck and the pause cases; either means
        // something more important than a zekr reminder is happening.
        _interrupted = event.begin;
      });
    } catch (e, st) {
      AppLogger.error(
        'Audio interruption watch failed to start',
        tag: 'CallInterruption',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _interrupted = false;
  }
}
