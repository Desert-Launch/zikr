import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/utils/helper/haptics_helper.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_ringing.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_player.dart';

/// Drives the in-app full-screen adhan alarm ([SNAdhanRinging]).
///
/// Owns none of the audio itself — [CBAdhanPlayer] is the app-wide playback
/// singleton and already handles source resolution, audio focus and the
/// lock-screen media item. This cubit starts it, mirrors its status, and
/// reports when the screen should dismiss.
class CBAdhanRinging extends Cubit<SAdhanRinging> {
  CBAdhanRinging(this._player, this._settings) : super(const SAdhanRinging());

  final CBAdhanPlayer _player;
  final BoxAdhanSettings _settings;

  StreamSubscription<SAdhanPlayer>? _playerSub;

  /// Starts the adhan for [prayerKey] and begins mirroring playback status.
  Future<void> start(String prayerKey) async {
    emit(
      state.copyWith(
        prayerKey: prayerKey,
        startedAt: DateTime.now(),
        voiceNameAr: _player.adhanForPrayer(prayerKey)?.nameAr ?? '',
      ),
    );

    // The in-app half of the vibration setting. On Android the OS notification
    // has already buzzed via the vibrating channel twin; here the app is in the
    // foreground, so the alert is this screen and the buzz has to come from us.
    // On iOS this is the ONLY thing the setting can drive — Apple gives no
    // app-level control over notification vibration. Fire-and-forget: a failed
    // buzz must never delay or block starting the adhan.
    if (_settings.current().vibrate) unawaited(HapticsHelper.complete());

    _playerSub?.cancel();
    _playerSub = _player.stream.listen((p) {
      final playing = p.status == AdhanPlayerStatus.playing;
      // Completed or errored means there's nothing left to listen to, so the
      // screen has served its purpose and should close.
      final finished =
          p.status == AdhanPlayerStatus.completed ||
          p.status == AdhanPlayerStatus.error;
      emit(state.copyWith(playing: playing, stopped: finished));
    });

    await _player.playForPrayer(prayerKey);
  }

  /// User pressed Stop. Silences the adhan and marks the screen for dismissal.
  Future<void> stop() async {
    await _player.stop();
    emit(state.copyWith(playing: false, stopped: true));
  }

  @override
  Future<void> close() async {
    await _playerSub?.cancel();
    return super.close();
  }
}
