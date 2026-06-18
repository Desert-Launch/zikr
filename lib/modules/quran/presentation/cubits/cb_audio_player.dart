import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/e_sleep_timer.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_ensure_ayah_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_playback_prefs.dart';
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
    required UCGetPlaybackPrefs getPrefs,
    required UCSavePlaybackPrefs savePrefs,
  }) : _quran = quran,
       _reciters = reciters,
       _ensure = ensure,
       _getPrefs = getPrefs,
       _savePrefs = savePrefs,
       _player = AudioPlayer(),
       super(const SAudioPlayer()) {
    _hydrate();
    _hydratePrefs();
    _wireStreams();
  }

  final RQuran _quran;
  final UCGetReciters _reciters;
  final UCEnsureAyahDownloaded _ensure;
  final UCGetPlaybackPrefs _getPrefs;
  final UCSavePlaybackPrefs _savePrefs;
  final AudioPlayer _player;

  String? _activeReciterId;
  String? _activeReciterName;

  /// Surah metadata for the active queue (for media-notification titles).
  MSurah? _activeSurah;

  /// Bumped on every new play session (playFrom/playRange/stop) so stale async
  /// ensure/advance callbacks from a previous session become no-ops.
  int _playToken = 0;

  /// Completed passes of the current repeat unit (ayah/range/surah). Reset when
  /// a new queue starts; compared against [EPlaybackOptions.repeatCount].
  int _completedPasses = 0;
  bool _resumeAfterInterruption = false;

  /// Active timed sleep-timer; fires once to fade out and stop.
  Timer? _sleepTimer;

  /// When set, playback stops at the next ayah/surah boundary (checked in
  /// [_onTrackCompleted]). Null when no boundary sleep mode is armed.
  ESleepTimer? _stopAtBoundary;

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

  /// Loads persisted playback preferences (speed, repeat mode/count, …) into
  /// state. The player speed itself is (re)applied per ayah in [_playAt], so no
  /// source needs to be loaded at construction time.
  Future<void> _hydratePrefs() async {
    final res = await _getPrefs();
    res.fold((_) {}, (opts) => emit(state.copyWith(options: opts)));
  }

  /// Persists the current durable playback options (fire-and-forget).
  void _persistOptions() => unawaited(_savePrefs(state.options));

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
    _completedPasses = 0;
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
      // All looping is handled manually in _onUnitCompleted so every track
      // fires `completed`. LoopMode.one would suppress that event and break
      // finite repeat counts.
      await _player.setLoopMode(LoopMode.off);
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

  /// Reached the end of the current ayah. Advances within the unit, loops the
  /// unit, advances to the next unit, or finishes — per the active repeat mode.
  void _onTrackCompleted() {
    final idx = state.queueIndex;
    if (idx == null) {
      emit(state.copyWith(status: PlayerStatus.completed));
      return;
    }
    // Sleep timer (boundary modes) wins over repeat: stop at this ayah/surah.
    if (_stopAtBoundary != null) {
      final stopNow =
          _stopAtBoundary == ESleepTimer.endOfAyah ||
          (_stopAtBoundary == ESleepTimer.endOfSurah &&
              _isCurrentAyahSurahEnd());
      if (stopNow) {
        _stopAtBoundary = null;
        unawaited(stop());
        return;
      }
    }
    // Still inside the current block → play its next ayah.
    if (idx + 1 < state.queue.length) {
      unawaited(_playAt(idx + 1, _playToken));
      return;
    }
    // End of the queue (singleAyah always lands here — its queue is length 1).
    if (state.options.repeatMode == RepeatMode.off) {
      unawaited(_advanceToNextSurahOrStop());
      return;
    }
    _onUnitCompleted();
  }

  /// One full pass of the repeat unit (ayah / range / surah) just finished.
  /// Replays it until [EPlaybackOptions.repeatCount] passes are done (0 means
  /// infinite), then stops or advances per [EPlaybackOptions.afterRepeat].
  void _onUnitCompleted() {
    _completedPasses++;
    final target = state.options.repeatCount;
    if (target == 0 || _completedPasses < target) {
      unawaited(_playAt(0, _playToken)); // replay the unit from its start
      return;
    }
    if (state.options.afterRepeat == EAfterRepeat.continueNext) {
      unawaited(_advanceAfterRepeat());
    } else {
      emit(state.copyWith(status: PlayerStatus.completed));
    }
  }

  /// Repeat-off reached the end of the surah → roll into the next surah (when
  /// [EPlaybackOptions.autoAdvanceSurah]) or finish at the end of the Qur'an.
  Future<void> _advanceToNextSurahOrStop() async {
    final cur = state.currentAyah;
    if (!state.options.autoAdvanceSurah || cur == null || cur.surah >= 114) {
      emit(state.copyWith(status: PlayerStatus.completed));
      return;
    }
    await playFrom(ParamAyahRef(surah: cur.surah + 1, ayah: 1));
  }

  /// A finite repeat finished and the user chose to continue. Moves to the next
  /// unit for the mode: singleAyah → next ayah (repeated again — a memorisation
  /// march), surah → next surah (repeated again), range → a plain play-through
  /// past the range to the end of the surah.
  Future<void> _advanceAfterRepeat() async {
    final cur = state.currentAyah;
    if (cur == null) {
      emit(state.copyWith(status: PlayerStatus.completed));
      return;
    }
    switch (state.options.repeatMode) {
      case RepeatMode.singleAyah:
        final next = await _nextAyahRef(cur);
        if (next == null) {
          emit(state.copyWith(status: PlayerStatus.completed));
          return;
        }
        await playFrom(next);
      case RepeatMode.surah:
        if (!state.options.autoAdvanceSurah || cur.surah >= 114) {
          emit(state.copyWith(status: PlayerStatus.completed));
          return;
        }
        await playFrom(ParamAyahRef(surah: cur.surah + 1, ayah: 1));
      case RepeatMode.range:
        final last = state.queue.isNotEmpty ? state.queue.last : cur;
        final next = await _nextAyahRef(last);
        if (next == null) {
          emit(state.copyWith(status: PlayerStatus.completed));
          return;
        }
        // The range repeat is done; continue as a normal play-through. The mode
        // flip is in-memory only (not persisted).
        emit(
          state.copyWith(
            options: state.options.copyWith(repeatMode: RepeatMode.off),
          ),
        );
        await playFrom(next);
      case RepeatMode.off:
        emit(state.copyWith(status: PlayerStatus.completed));
    }
  }

  /// The ayah after [ref], crossing into the next surah when
  /// [EPlaybackOptions.autoAdvanceSurah] allows. Null at the end of the Qur'an.
  Future<ParamAyahRef?> _nextAyahRef(ParamAyahRef ref) async {
    final surah = (await _quran.getSurah(
      ref.surah,
    )).fold<MSurah?>((_) => null, (s) => s);
    final last = surah?.totalAyah ?? ref.ayah;
    if (ref.ayah < last) {
      return ParamAyahRef(surah: ref.surah, ayah: ref.ayah + 1);
    }
    if (state.options.autoAdvanceSurah && ref.surah < 114) {
      return ParamAyahRef(surah: ref.surah + 1, ayah: 1);
    }
    return null;
  }

  /// Builds the queue (= the repeat unit) for [ref] under the current mode.
  List<ParamAyahRef> _buildUnit(
    ParamAyahRef ref,
    MSurah? surah, {
    bool toEndOfSurah = true,
  }) {
    final last = surah?.totalAyah ?? ref.ayah;
    switch (state.options.repeatMode) {
      case RepeatMode.singleAyah:
        return [ref];
      case RepeatMode.range:
        final from = state.options.rangeFrom;
        final to = state.options.rangeTo;
        if (from != null && to != null && from.surah == ref.surah) {
          final lo = from.ayah <= to.ayah ? from.ayah : to.ayah;
          final hi = from.ayah <= to.ayah ? to.ayah : from.ayah;
          return [
            for (int a = lo; a <= hi; a++)
              ParamAyahRef(surah: ref.surah, ayah: a),
          ];
        }
        return [ref];
      case RepeatMode.surah:
        return [
          for (int a = 1; a <= last; a++)
            ParamAyahRef(surah: ref.surah, ayah: a),
        ];
      case RepeatMode.off:
        final end = toEndOfSurah ? last : ref.ayah;
        return [
          for (int a = ref.ayah; a <= end; a++)
            ParamAyahRef(surah: ref.surah, ayah: a),
        ];
    }
  }

  Future<void> playFrom(ParamAyahRef ref, {bool toEndOfSurah = true}) async {
    try {
      emit(state.copyWith(status: PlayerStatus.loading, clearError: true));
      final reciterId = await _resolveReciterId();
      final surahRes = await _quran.getSurah(ref.surah);
      final surah = surahRes.fold<MSurah?>((_) => null, (s) => s);
      final queue = _buildUnit(ref, surah, toEndOfSurah: toEndOfSurah);
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
      final lo = from.ayah <= to.ayah ? from.ayah : to.ayah;
      final hi = from.ayah <= to.ayah ? to.ayah : from.ayah;
      // Set range mode (in-memory) so the repeat engine loops the block.
      emit(
        state.copyWith(
          status: PlayerStatus.loading,
          clearError: true,
          options: state.options.copyWith(
            repeatMode: RepeatMode.range,
            rangeFrom: ParamAyahRef(surah: from.surah, ayah: lo),
            rangeTo: ParamAyahRef(surah: from.surah, ayah: hi),
          ),
        ),
      );
      final reciterId = await _resolveReciterId();
      final surahRes = await _quran.getSurah(from.surah);
      final surah = surahRes.fold<MSurah?>((_) => null, (s) => s);
      final queue = <ParamAyahRef>[
        for (int a = lo; a <= hi; a++) ParamAyahRef(surah: from.surah, ayah: a),
      ];
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
    _persistOptions();
    await playFrom(ref); // mode is singleAyah → builds a [ref] unit
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() async {
    _playToken++; // invalidate any in-flight ensure/advance
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _stopAtBoundary = null;
    await _player.stop();
    emit(
      state.copyWith(
        status: PlayerStatus.idle,
        sleepTimer: ESleepTimer.off,
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
    _persistOptions();
    await _player.setSpeed(speed);
  }

  /// Switches repeat mode. If something is playing, the unit is rebuilt around
  /// the current ayah and restarted so the new mode takes effect immediately.
  Future<void> setRepeatMode(RepeatMode mode) async {
    emit(state.copyWith(options: state.options.copyWith(repeatMode: mode)));
    _persistOptions();
    final ref = state.currentAyah;
    if (ref == null) return;
    final surahRes = await _quran.getSurah(ref.surah);
    final surah = surahRes.fold<MSurah?>((_) => null, (s) => s);
    final queue = _buildUnit(ref, surah);
    await _startQueue(
      queue,
      surah,
      _activeReciterId ?? await _resolveReciterId(),
    );
  }

  Future<void> setRepeatCount(int count) async {
    final clamped = count < 0 ? 0 : count;
    emit(state.copyWith(options: state.options.copyWith(repeatCount: clamped)));
    _persistOptions();
    _completedPasses = 0; // restart the counting window
  }

  Future<void> setAfterRepeat(EAfterRepeat value) async {
    emit(state.copyWith(options: state.options.copyWith(afterRepeat: value)));
    _persistOptions();
  }

  void toggleAutoAdvanceSurah() {
    emit(
      state.copyWith(
        options: state.options.copyWith(
          autoAdvanceSurah: !state.options.autoAdvanceSurah,
        ),
      ),
    );
    _persistOptions();
  }

  /// Sets a from–to repeat range (single surah) and starts looping it.
  Future<void> setRepeatRange(ParamAyahRef from, ParamAyahRef to) =>
      playRange(from, to);

  /// Arms, changes, or clears the sleep timer. Timed options start a countdown
  /// that fades out and stops; boundary options stop at the next ayah / surah
  /// boundary (handled in [_onTrackCompleted]) and beat an active repeat.
  Future<void> setSleepTimer(ESleepTimer timer) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _stopAtBoundary = null;
    emit(state.copyWith(sleepTimer: timer));
    if (timer == ESleepTimer.off) return;
    if (timer.isBoundary) {
      _stopAtBoundary = timer;
      return;
    }
    final d = timer.duration;
    if (d != null) {
      _sleepTimer = Timer(d, () => unawaited(_fadeOutAndStop()));
    }
  }

  /// Gently fades the volume to zero over ~3s, then stops. Aborts (restoring
  /// full volume) if a new play session starts mid-fade.
  Future<void> _fadeOutAndStop() async {
    final token = _playToken;
    for (double v = 1.0; v > 0; v -= 0.1) {
      if (token != _playToken) {
        await _player.setVolume(1);
        return;
      }
      await _player.setVolume(v.clamp(0.0, 1.0));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (token != _playToken) {
      await _player.setVolume(1);
      return;
    }
    await stop();
    await _player.setVolume(1);
  }

  /// True when the current ayah is the last of its surah.
  bool _isCurrentAyahSurahEnd() {
    final cur = state.currentAyah;
    final total = _activeSurah?.totalAyah;
    return cur != null && total != null && cur.ayah >= total;
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
    _sleepTimer?.cancel();
    await _player.dispose();
    return super.close();
  }
}
