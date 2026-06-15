import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_ensure_ayah_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';

/// App-wide audio player. Singleton (registered via Modular.addSingleton).
///
/// Playback is strictly offline and plays **one ayah at a time**: each ayah is
/// ensured on disk, set as a single local source, and played; on completion we
/// advance to the next ayah in [SAudioPlayer.queue] (prefetching its file ahead
/// of time so the gap stays small). We deliberately avoid a growing
/// `ConcatenatingAudioSource` — appending to one while it plays under
/// just_audio_background makes the auto-advanced item silent until a manual
/// pause/resume re-issues `play()`.
class CBAudioPlayer extends Cubit<SAudioPlayer> {
  CBAudioPlayer({
    required RQuran quran,
    required UCGetReciters reciters,
    required UCEnsureAyahDownloaded ensure,
  }) : _quran = quran,
       _reciters = reciters,
       _ensure = ensure,
       _player = AudioPlayer(),
       super(const SAudioPlayer()) {
    _hydrate();
    _wireStreams();
  }

  final RQuran _quran;
  final UCGetReciters _reciters;
  final UCEnsureAyahDownloaded _ensure;
  final AudioPlayer _player;

  String? _activeReciterId;
  String? _activeReciterName;

  /// Surah metadata for the active queue (for media-notification titles).
  MSurah? _activeSurah;

  /// Bumped on every new play session (playFrom/playRange/stop) so stale async
  /// ensure/advance callbacks from a previous session become no-ops.
  int _playToken = 0;
  bool _resumeAfterInterruption = false;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlaybackEvent>? _errSub;
  StreamSubscription<void>? _noisySub;
  StreamSubscription<AudioInterruptionEvent>? _interruptSub;

  Future<void> _hydrate() async {
    final res = await _reciters.active();
    res.fold((_) {}, (r) {
      _activeReciterId = r.id;
      _activeReciterName = r.arabic.isNotEmpty ? r.arabic : r.name;
      emit(state.copyWith(reciterId: r.id));
    });
  }

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((ps) {
      // End of the current ayah → advance manually (or finish the queue).
      if (ps.processingState == ProcessingState.completed) {
        _onTrackCompleted();
        return;
      }
      final PlayerStatus next;
      switch (ps.processingState) {
        case ProcessingState.idle:
          next = PlayerStatus.idle;
        case ProcessingState.loading:
          next = PlayerStatus.loading;
        case ProcessingState.buffering:
          next = PlayerStatus.buffering;
        case ProcessingState.ready:
          next = ps.playing ? PlayerStatus.playing : PlayerStatus.paused;
        case ProcessingState.completed:
          next = PlayerStatus.completed; // handled above
      }
      emit(state.copyWith(status: next));
    });

    _posSub = _player.positionStream.listen(
      (p) => emit(state.copyWith(position: p)),
    );
    _durSub = _player.durationStream.listen((d) {
      emit(state.copyWith(duration: d ?? Duration.zero));
    });
    // just_audio 0.9.x surfaces playback errors through `playbackEventStream`'s
    // error channel — there is no dedicated `errorStream` until 0.10.x.
    _errSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        if (e is PlayerException) {
          unawaited(_handlePlaybackError(e));
        } else {
          AppLogger.warning('Playback stream error: $e', tag: 'CBAudioPlayer');
        }
      },
    );

    unawaited(_configureSession());
  }

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _noisySub = session.becomingNoisyEventStream.listen((_) async {
        // Headphone unplugged / Bluetooth disconnect → always pause.
        if (_player.playing) {
          AppLogger.info('Audio becoming noisy → pause', tag: 'CBAudioPlayer');
          await _player.pause();
        }
      });
      _interruptSub = session.interruptionEventStream.listen(_onInterruption);
    } catch (e, st) {
      AppLogger.warning(
        'audio_session configure failed: $e',
        tag: 'CBAudioPlayer',
      );
      AppLogger.error(
        'audio_session configure',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
    }
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      _resumeAfterInterruption = _player.playing;
      if (_resumeAfterInterruption) {
        await _player.pause();
      }
      return;
    }
    // Interruption ended.
    if (event.type == AudioInterruptionType.pause && _resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      await _player.play();
    } else {
      _resumeAfterInterruption = false;
    }
  }

  /// just_audio failed to play the current (local) source. Strictly offline, so
  /// there is no online fallback — skip to the next ayah if there is one.
  Future<void> _handlePlaybackError(PlayerException error) async {
    AppLogger.warning(
      'Audio playback error: ${error.message}',
      tag: 'CBAudioPlayer',
    );
    final idx = state.queueIndex;
    if (idx != null && idx + 1 < state.queue.length) {
      unawaited(_playAt(idx + 1, _playToken));
    } else {
      emit(state.copyWith(status: PlayerStatus.error, error: error.message));
    }
  }

  Future<void> setReciter(String reciterId) async {
    _activeReciterId = reciterId;
    emit(state.copyWith(reciterId: reciterId));
  }

  /// Builds a local-file audio source (with media-notification metadata) for an
  /// already-downloaded ayah. `Uri.file` (not `Uri.parse`) is required for
  /// local files to play on Android.
  AudioSource _localSource(MSurah? surah, ParamAyahRef ref, String path) {
    final tag = MediaItem(
      id: '${ref.surah}_${ref.ayah}',
      album:
          'القرآن الكريم${_activeReciterName != null ? ' - $_activeReciterName' : ''}',
      title: '${surah?.arabic ?? ''} - الآية ${ref.ayah}',
      artist: _activeReciterName ?? '',
    );
    return AudioSource.uri(Uri.file(path), tag: tag);
  }

  Future<String> _resolveReciterId() async {
    return _activeReciterId ??
        (await _reciters.active()).fold<String?>((_) => null, (r) => r.id) ??
        'alafasy';
  }

  /// Replaces the queue and starts playing from its first ayah.
  Future<void> _startQueue(
    List<ParamAyahRef> queue,
    MSurah? surah,
    String reciterId,
  ) async {
    if (queue.isEmpty) {
      emit(state.copyWith(status: PlayerStatus.idle));
      return;
    }
    _activeSurah = surah;
    _activeReciterId = reciterId;
    _playToken++;
    final token = _playToken;
    emit(state.copyWith(queue: queue, reciterId: reciterId, clearError: true));
    await _playAt(0, token);
  }

  /// Ensures the ayah at [index] is on disk, sets it as the single audio source
  /// and plays it. [token] guards against a superseded play session.
  Future<void> _playAt(int index, int token) async {
    if (token != _playToken) return;
    final queue = state.queue;
    if (index < 0 || index >= queue.length) {
      emit(state.copyWith(status: PlayerStatus.completed));
      return;
    }
    final ref = queue[index];
    final reciterId = _activeReciterId ?? 'alafasy';
    emit(
      state.copyWith(
        queueIndex: index,
        currentAyah: ref,
        status: PlayerStatus.loading,
        clearError: true,
      ),
    );

    final res = await _ensure(ref, reciterId);
    if (token != _playToken) return;
    final path = res.fold<String?>((failure) {
      AppLogger.warning(
        'Ensure ayah ${ref.key} failed: ${failure.message}',
        tag: 'CBAudioPlayer',
      );
      return null;
    }, (p) => p);
    if (path == null) {
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          error: 'quran_audio_offline_error'.tr(),
        ),
      );
      return;
    }

    try {
      await _player.setAudioSource(_localSource(_activeSurah, ref, path));
      if (token != _playToken) return;
      await _player.setSpeed(state.options.speed);
      await _player.setLoopMode(
        state.options.repeatMode == RepeatMode.singleAyah
            ? LoopMode.one
            : LoopMode.off,
      );
      await _player.play();
    } catch (e, st) {
      if (token != _playToken) return;
      AppLogger.error(
        'playAt failed',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
      emit(state.copyWith(status: PlayerStatus.error, error: e.toString()));
      return;
    }

    // Prefetch the next ayah's file so auto-advance stays near-gapless.
    unawaited(_prefetch(index + 1, token));
  }

  /// Best-effort background download of the ayah at [index] (skips if already on
  /// disk). Not done while repeating a single ayah.
  Future<void> _prefetch(int index, int token) async {
    if (token != _playToken) return;
    if (state.options.repeatMode == RepeatMode.singleAyah) return;
    final queue = state.queue;
    if (index < 0 || index >= queue.length) return;
    await _ensure(queue[index], _activeReciterId ?? 'alafasy');
  }

  /// Reached the end of the current ayah → advance, loop, or finish.
  void _onTrackCompleted() {
    final idx = state.queueIndex;
    if (idx == null) {
      emit(state.copyWith(status: PlayerStatus.completed));
      return;
    }
    final nextIndex = idx + 1;
    if (nextIndex < state.queue.length) {
      unawaited(_playAt(nextIndex, _playToken));
    } else if (state.options.repeatMode == RepeatMode.range &&
        state.queue.isNotEmpty) {
      unawaited(_playAt(0, _playToken));
    } else {
      emit(state.copyWith(status: PlayerStatus.completed));
    }
  }

  Future<void> playFrom(ParamAyahRef ref, {bool toEndOfSurah = true}) async {
    try {
      emit(state.copyWith(status: PlayerStatus.loading, clearError: true));
      final reciterId = await _resolveReciterId();
      final surahRes = await _quran.getSurah(ref.surah);
      final surah = surahRes.fold<MSurah?>((_) => null, (s) => s);
      final endAyah = toEndOfSurah ? (surah?.totalAyah ?? ref.ayah) : ref.ayah;

      final queue = <ParamAyahRef>[
        for (int a = ref.ayah; a <= endAyah; a++)
          ParamAyahRef(surah: ref.surah, ayah: a),
      ];
      await _startQueue(queue, surah, reciterId);
    } catch (e, st) {
      AppLogger.error(
        'playFrom failed',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
      emit(state.copyWith(status: PlayerStatus.error, error: e.toString()));
    }
  }

  Future<void> playRange(ParamAyahRef from, ParamAyahRef to) async {
    try {
      // v1: only supports ranges inside a single surah; cross-surah ranges
      // can be added later by stitching `ayatOfSurah` results.
      if (from.surah != to.surah) {
        AppLogger.warning(
          'Cross-surah ranges not supported yet',
          tag: 'CBAudioPlayer',
        );
        return;
      }
      emit(state.copyWith(status: PlayerStatus.loading, clearError: true));
      final reciterId = await _resolveReciterId();
      final surahRes = await _quran.getSurah(from.surah);
      final surah = surahRes.fold<MSurah?>((_) => null, (s) => s);
      final ayatRes = await _quran.ayatOfSurah(from.surah);
      final queue = ayatRes.fold<List<ParamAyahRef>>(
        (_) => [],
        (list) => list
            .where((r) => r.ayah >= from.ayah && r.ayah <= to.ayah)
            .toList(),
      );
      await _startQueue(queue, surah, reciterId);
    } catch (e, st) {
      AppLogger.error(
        'playRange failed',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
      emit(state.copyWith(status: PlayerStatus.error, error: e.toString()));
    }
  }

  Future<void> repeatSingle(ParamAyahRef ref) async {
    emit(
      state.copyWith(
        options: state.options.copyWith(repeatMode: RepeatMode.singleAyah),
      ),
    );
    await playFrom(ref, toEndOfSurah: false);
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() async {
    _playToken++; // invalidate any in-flight ensure/advance
    await _player.stop();
    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        clearCurrentAyah: true,
        clearQueueIndex: true,
        queue: const [],
      ),
    );
  }

  Future<void> next() async {
    final idx = state.queueIndex;
    if (idx != null && idx + 1 < state.queue.length) {
      await _playAt(idx + 1, _playToken);
    }
  }

  Future<void> previous() async {
    final idx = state.queueIndex;
    if (idx == null) return;
    // Restart the current ayah if we're well into it, otherwise step back.
    if (idx == 0 || state.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      if (!_player.playing) await _player.play();
    } else {
      await _playAt(idx - 1, _playToken);
    }
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) async {
    emit(state.copyWith(options: state.options.copyWith(speed: speed)));
    await _player.setSpeed(speed);
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    emit(state.copyWith(options: state.options.copyWith(repeatMode: mode)));
    await _player.setLoopMode(
      mode == RepeatMode.singleAyah ? LoopMode.one : LoopMode.off,
    );
  }

  Stream<ParamAyahRef?> get currentAyahStream =>
      stream.map((s) => s.currentAyah).distinct((a, b) => a?.key == b?.key);

  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _errSub?.cancel();
    await _noisySub?.cancel();
    await _interruptSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
