import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio_player.dart';

/// App-wide live-radio player. Singleton (registered via `addLazySingleton`) so
/// playback survives navigating away from the radio screen and runs in the
/// background media notification (just_audio_background is initialised in main).
///
/// Unlike [CBAudioPlayer] there is no queue: a station is a single live stream
/// that plays until paused/stopped or replaced by another station.
class CBRadioPlayer extends Cubit<SRadioPlayer> {
  CBRadioPlayer()
      : _player = AudioPlayer(),
        super(const SRadioPlayer()) {
    _wireStreams();
  }

  final AudioPlayer _player;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlaybackEvent>? _errSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptSub;
  bool _resumeAfterInterruption = false;

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((ps) {
      final RadioPlayerStatus next;
      switch (ps.processingState) {
        case ProcessingState.idle:
          next = RadioPlayerStatus.idle;
        case ProcessingState.loading:
          next = RadioPlayerStatus.loading;
        case ProcessingState.buffering:
          next = RadioPlayerStatus.buffering;
        case ProcessingState.ready:
          next = ps.playing
              ? RadioPlayerStatus.playing
              : RadioPlayerStatus.paused;
        case ProcessingState.completed:
          // A live stream shouldn't "complete"; treat it as idle if it does.
          next = RadioPlayerStatus.idle;
      }
      emit(state.copyWith(status: next));
    });

    // just_audio 0.9.x surfaces playback errors via the event stream's error
    // channel (no dedicated errorStream until 0.10.x).
    _errSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        AppLogger.warning('Radio stream error: $e', tag: 'CBRadioPlayer');
        emit(state.copyWith(status: RadioPlayerStatus.error, error: e.toString()));
      },
    );

    unawaited(_configureSession());
  }

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _interruptSub = session.interruptionEventStream.listen(_onInterruption);
    } catch (e, st) {
      AppLogger.error(
        'audio_session configure',
        error: e,
        stackTrace: st,
        tag: 'CBRadioPlayer',
      );
    }
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      _resumeAfterInterruption = _player.playing;
      if (_resumeAfterInterruption) await _player.pause();
      return;
    }
    if (event.type == AudioInterruptionType.pause && _resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      await _player.play();
    } else {
      _resumeAfterInterruption = false;
    }
  }

  /// Tapping a station: toggles play/pause if it's the active one, otherwise
  /// switches to and plays the new station.
  Future<void> toggle(MRadioStation station) async {
    if (state.isActive(station.id)) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }
    await play(station);
  }

  Future<void> play(MRadioStation station) async {
    emit(state.copyWith(
      current: station,
      status: RadioPlayerStatus.loading,
      clearError: true,
    ));
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(station.url),
          tag: MediaItem(
            id: station.id,
            album: 'إذاعة القرآن الكريم',
            title: station.name,
            artist: station.country ?? '',
            artUri: MediaArtwork.uri,
          ),
        ),
      );
      await _player.play();
    } catch (e, st) {
      AppLogger.error(
        'Radio play failed (${station.id})',
        error: e,
        stackTrace: st,
        tag: 'CBRadioPlayer',
      );
      emit(state.copyWith(status: RadioPlayerStatus.error, error: e.toString()));
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> stop() async {
    await _player.stop();
    emit(state.copyWith(status: RadioPlayerStatus.idle, clearCurrent: true));
  }

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _errSub?.cancel();
    await _interruptSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
