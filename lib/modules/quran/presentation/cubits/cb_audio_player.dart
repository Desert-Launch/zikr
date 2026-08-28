import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_audio_source.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/e_sleep_timer.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_ensure_ayah_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_resolve_ayah_source.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_playback_prefs.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';

/// App-wide audio player. Singleton (registered via Modular.addSingleton).
///
/// Plays a whole **unit** — the block [SAudioPlayer.queue] holds under the
/// active repeat mode — as one [ConcatenatingAudioSource]. The platform
/// (ExoPlayer / AVQueuePlayer) then moves between ayat itself, which is the
/// only way the seam stays inaudible: driving each ayah from Dart meant a
/// platform round trip plus a fresh prepare on every `completed` event, and
/// that gap is heard between every two ayat.
///
/// Consequences of the platform owning the transition:
/// - the current ayah is read from `currentIndexStream`, not set by us;
/// - `completed` marks the end of the whole playlist, not of one ayah, so
///   sleep-timer boundaries are judged on index changes instead;
/// - a finite repeat is laid out as N copies of the unit and an infinite one
///   runs under [LoopMode.all], so repeat seams are gapless too.
///
/// Still offline-first: every entry resolves to a local file when it is on
/// disk, otherwise to a CDN URL streamed in place, and ayat are downloaded in
/// the background so a later replay is local. The playlist is built once per
/// unit and never appended to while it plays — under just_audio_background that
/// leaves the auto-advanced item silent until a manual pause/resume.
///
/// Ayah 1 of a surah is preceded by the basmalah, an entry that carries the
/// following ayah's index so the reader keeps highlighting it — see
/// [_shouldLeadWithBasmalah].
class CBAudioPlayer extends Cubit<SAudioPlayer> {
  CBAudioPlayer({
    required RQuran quran,
    required UCGetReciters reciters,
    required UCEnsureAyahDownloaded ensure,
    required UCResolveAyahSource resolve,
    required UCGetPlaybackPrefs getPrefs,
    required UCSavePlaybackPrefs savePrefs,
  }) : _quran = quran,
       _reciters = reciters,
       _ensure = ensure,
       _resolve = resolve,
       _getPrefs = getPrefs,
       _savePrefs = savePrefs,
       _player = AudioPlayer(),
       super(const SAudioPlayer()) {
    AudioFocus.instance.register(this, stop);
    _hydrate();
    _hydratePrefs();
    _wireStreams();
  }

  final RQuran _quran;
  final UCGetReciters _reciters;
  final UCEnsureAyahDownloaded _ensure;
  final UCResolveAyahSource _resolve;
  final UCGetPlaybackPrefs _getPrefs;
  final UCSavePlaybackPrefs _savePrefs;
  final AudioPlayer _player;

  String? _activeReciterId;
  String? _activeReciterName;

  /// Surah metadata for the active queue (for media-notification titles).
  MSurah? _activeSurah;

  /// Ceiling on how many clips one playlist may hold. A repeat count that would
  /// exceed it is played out over several playlists instead — the seam between
  /// them is the only one that is not gapless.
  static const int _maxPlaylistItems = 600;

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
  /// [_onPlaylistIndexChanged]). Null when no boundary sleep mode is armed.
  ESleepTimer? _stopAtBoundary;

  /// The playlist currently handed to the platform, one entry per audio clip:
  /// every ayah of the unit plus any basmalah lead-in, repeated once per
  /// laid-out pass. Maps a platform index back to an ayah.
  List<_Track> _tracks = const [];

  /// Index into [_tracks] the platform is playing, to tell which entry a change
  /// has just left behind.
  int? _trackIndex;


  /// Last seen processing state, to log only on transitions.
  ProcessingState? _lastProcessingState;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<int?>? _idxSub;
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
  /// state. The player speed itself is applied per playlist in [_startQueue],
  /// so no source needs to be loaded at construction time.
  Future<void> _hydratePrefs() async {
    final res = await _getPrefs();
    res.fold((_) {}, (opts) => emit(state.copyWith(options: opts)));
  }

  /// Persists the current durable playback options (fire-and-forget).
  void _persistOptions() => unawaited(_savePrefs(state.options));

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((ps) {
      // Trace processing-state transitions to diagnose auto-advance issues.
      if (ps.processingState != _lastProcessingState) {
        _lastProcessingState = ps.processingState;
        AppLogger.info(
          'state=${ps.processingState.name} playing=${ps.playing} '
          'idx=${state.queueIndex} queue=${state.queue.length}',
          tag: 'CBAudioPlayer',
        );
      }
      // The platform advances between ayat by itself, so `completed` now marks
      // the end of the whole playlist rather than of one ayah.
      if (ps.processingState == ProcessingState.completed) {
        _onPlaylistCompleted();
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

    _idxSub = _player.currentIndexStream.listen(_onPlaylistIndexChanged);

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
    final idx = _trackIndex;
    if (idx != null && idx + 1 < _tracks.length) {
      unawaited(_player.seekToNext());
    } else {
      emit(state.copyWith(status: PlayerStatus.error, error: error.message));
    }
  }

  /// Switches the active reciter.
  ///
  /// When a unit is already loaded it is rebuilt in the new voice and the
  /// current ayah restarts from its beginning, so the change is heard at once
  /// rather than at the next ayah. Playback that was paused stays paused — the
  /// new voice is simply what `resume` will play.
  Future<void> setReciter(String reciterId) async {
    if (_activeReciterId == reciterId) return;
    _activeReciterId = reciterId;
    await _applyReciterName(reciterId);
    emit(state.copyWith(reciterId: reciterId));

    // Nothing loaded (idle/completed/error) → the id alone is enough; the next
    // play session resolves against it.
    const restartable = <PlayerStatus>{
      PlayerStatus.playing,
      PlayerStatus.paused,
      PlayerStatus.loading,
      PlayerStatus.buffering,
    };
    final queue = state.queue;
    if (queue.isEmpty || !restartable.contains(state.status)) return;

    await _startQueue(
      queue,
      _activeSurah,
      reciterId,
      startQueueIndex: state.queueIndex ?? 0,
      autoPlay: state.status != PlayerStatus.paused,
    );
  }

  /// Caches [reciterId]'s display name for the media-notification metadata.
  Future<void> _applyReciterName(String reciterId) async {
    final res = await _reciters();
    res.fold((_) {}, (list) {
      for (final r in list) {
        if (r.id != reciterId) continue;
        _activeReciterName = r.arabic.isNotEmpty ? r.arabic : r.name;
        return;
      }
    });
  }

  /// Builds an audio source (with media-notification metadata) for an ayah.
  /// [isLocal] selects `Uri.file` for a downloaded file (required for local
  /// playback on Android) versus `Uri.parse` for a streamed CDN URL.
  AudioSource _ayahSource(
    MSurah? surah,
    ParamAyahRef ref,
    String uri, {
    required bool isLocal,
  }) {
    final tag = MediaItem(
      id: '${ref.surah}_${ref.ayah}',
      album:
          'القرآن الكريم${_activeReciterName != null ? ' - $_activeReciterName' : ''}',
      title: '${surah?.arabic ?? ''} - الآية ${ref.ayah}',
      artist: _activeReciterName ?? '',
      artUri: MediaArtwork.uri,
    );
    return AudioSource.uri(
      isLocal ? Uri.file(uri) : Uri.parse(uri),
      tag: tag,
    );
  }

  /// Audio source for the basmalah lead-in that precedes [ref] (ayah 1 of
  /// [surah]). Carries its own notification metadata so the media controls read
  /// as the basmalah rather than as the ayah that follows it.
  AudioSource _basmalahSource(
    MSurah? surah,
    ParamAyahRef ref,
    String uri, {
    required bool isLocal,
  }) {
    final tag = MediaItem(
      id: 'basmalah_${ref.surah}',
      album:
          'القرآن الكريم${_activeReciterName != null ? ' - $_activeReciterName' : ''}',
      title: '${surah?.arabic ?? ''} - بسم الله الرحمن الرحيم',
      artist: _activeReciterName ?? '',
      artUri: MediaArtwork.uri,
    );
    return AudioSource.uri(
      isLocal ? Uri.file(uri) : Uri.parse(uri),
      tag: tag,
    );
  }

  Future<String> _resolveReciterId() async {
    return _activeReciterId ??
        (await _reciters.active()).fold<String?>((_) => null, (r) => r.id) ??
        'alafasy';
  }

  /// Replaces the queue and starts playing it as a single gapless playlist.
  ///
  /// Every ayah of the unit (plus any basmalah lead-in) is handed to the
  /// platform in one [ConcatenatingAudioSource], so ExoPlayer / AVQueuePlayer
  /// performs the ayah→ayah transition itself with no gap. Driving each ayah
  /// from Dart — load, then play, on every `completed` event — cost a round trip
  /// through the platform channel and a fresh prepare, which is audible.
  ///
  /// [startQueueIndex] starts the playlist on an ayah other than the first —
  /// used when the unit is rebuilt under the running session (a reciter switch)
  /// and playback should carry on where it stood. [autoPlay] false loads the
  /// playlist without starting it, so a paused session stays paused.
  Future<void> _startQueue(
    List<ParamAyahRef> queue,
    MSurah? surah,
    String reciterId, {
    int startQueueIndex = 0,
    bool autoPlay = true,
  }) async {
    if (queue.isEmpty) {
      emit(state.copyWith(status: PlayerStatus.idle));
      return;
    }
    final start = (startQueueIndex > 0 && startQueueIndex < queue.length)
        ? startQueueIndex
        : 0;
    _activeSurah = surah;
    _activeReciterId = reciterId;
    _playToken++;
    _completedPasses = 0;
    // Forget where the outgoing playlist stood: its index must not be compared
    // against the incoming one, or the switch reads as a wrap or a boundary.
    _trackIndex = null;
    final token = _playToken;
    emit(
      state.copyWith(
        queue: queue,
        reciterId: reciterId,
        queueIndex: start,
        currentAyah: queue[start],
        status: PlayerStatus.loading,
        clearError: true,
      ),
    );

    final pass = await _buildPass(queue, reciterId);
    if (token != _playToken) return;
    if (pass.isEmpty) {
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          error: 'quran_audio_offline_error'.tr(),
        ),
      );
      return;
    }

    // A finite repeat is laid out as N copies of the unit rather than replayed
    // on each `completed`, so the seam between passes is gapless too. An
    // infinite repeat cannot be laid out, so it loops the playlist instead —
    // also gapless, and [_onPassCompleted] counts the passes.
    final repeating = state.options.repeatMode != RepeatMode.off;
    final target = state.options.repeatCount;
    final passes = (repeating && target > 0)
        ? _passesThatFit(pass.length, target)
        : 1;
    _tracks = [
      for (var i = 0; i < passes; i++)
        for (final t in pass) t.onPass(i),
    ];

    try {
      // Free the shared just_audio_background slot from any other domain player
      // (radio/adhan/preview) before claiming it.
      await AudioFocus.instance.take(this);
      if (token != _playToken) return;
      await _player.setLoopMode(
        repeating && target == 0 ? LoopMode.all : LoopMode.off,
      );
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          children: [for (final t in _tracks) t.source],
        ),
        initialIndex: _trackIndexOf(start),
      );
      if (token != _playToken) return;
      await _player.setSpeed(state.options.speed);
      if (autoPlay) await _player.play();
      AppLogger.info(
        'playlist ${_tracks.length} item(s), $passes pass(es), '
        'from ${queue[start].key}',
        tag: 'CBAudioPlayer',
      );
    } catch (e, st) {
      if (token != _playToken) return;
      AppLogger.error(
        'startQueue failed',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          error: 'quran_audio_offline_error'.tr(),
        ),
      );
    }
  }

  /// Where in [_tracks] the ayah at [queueIndex] begins. Its basmalah lead-in
  /// is skipped when the playlist does not start at its first ayah: a rebuild
  /// mid-unit should resume on the ayah itself, not re-open with the basmalah.
  int _trackIndexOf(int queueIndex) {
    if (queueIndex <= 0) return 0;
    final i = _tracks.indexWhere(
      (t) => t.queueIndex == queueIndex && !t.isBasmalah,
    );
    return i < 0 ? 0 : i;
  }

  /// Resolves one pass of [queue] into playlist entries, in parallel — each
  /// resolve is a file-exists check or a URL build, so the whole surah costs
  /// about as much as a single ayah did.
  ///
  /// Ayat that cannot be resolved are dropped rather than failing the unit; an
  /// empty result means nothing at all was playable.
  Future<List<_Track>> _buildPass(
    List<ParamAyahRef> queue,
    String reciterId,
  ) async {
    final resolved = await Future.wait([
      for (final ref in queue) _resolve(ref, reciterId),
    ]);
    final basmalahIndexes = <int>[
      for (var i = 0; i < queue.length; i++)
        if (_shouldLeadWithBasmalah(queue[i])) i,
    ];
    // One resolve for the lead-in: it is the same clip wherever it appears.
    final lead = basmalahIndexes.isEmpty
        ? null
        : await _resolveBasmalah(reciterId);

    final tracks = <_Track>[];
    for (var i = 0; i < queue.length; i++) {
      final ref = queue[i];
      if (lead != null && basmalahIndexes.contains(i)) {
        tracks.add(
          _Track(
            queueIndex: i,
            ref: ref,
            isBasmalah: true,
            source: _basmalahSource(
              _activeSurah,
              ref,
              lead.uri,
              isLocal: lead.isLocal,
            ),
          ),
        );
      }
      final source = resolved[i].fold<EAyahAudioSource?>((failure) {
        AppLogger.warning(
          'Resolve ayah ${ref.key} failed: ${failure.message}',
          tag: 'CBAudioPlayer',
        );
        return null;
      }, (s) => s);
      if (source == null) continue;
      tracks.add(
        _Track(
          queueIndex: i,
          ref: ref,
          source: _ayahSource(
            _activeSurah,
            ref,
            source.uri,
            isLocal: source.isLocal,
          ),
        ),
      );
    }
    return tracks;
  }

  /// How many copies of a [passLength]-item unit to lay out for a [target]-pass
  /// repeat. Capped so a long surah repeated many times does not build an
  /// enormous playlist; the remaining passes are replayed on completion.
  int _passesThatFit(int passLength, int target) {
    final fits = _maxPlaylistItems ~/ passLength;
    return fits < 1 ? 1 : (fits < target ? fits : target);
  }

  /// True when [ref] should be preceded by the basmalah: it is the opening ayah
  /// of a surah that starts with one.
  ///
  /// Excluded: Al-Fatiha, whose ayah 1 *is* the basmalah (it would play twice),
  /// and At-Tawbah, which has no basmalah. Also skipped while repeating a single
  /// ayah — that mode is for memorisation, and re-hearing the basmalah on every
  /// pass gets in the way.
  bool _shouldLeadWithBasmalah(ParamAyahRef ref) =>
      ref.ayah == 1 &&
      ref.surah != 1 &&
      ref.surah != 9 &&
      state.options.repeatMode != RepeatMode.singleAyah;

  /// Resolves the basmalah clip for [reciterId]. It is Al-Fatiha 1:1, so this
  /// is the ordinary ayah resolver — local file when downloaded (which
  /// `BasmalahBootstrap` arranges for every reciter on first launch), otherwise
  /// streamed. Null when it cannot be resolved at all; the unit then plays
  /// without a lead-in.
  Future<EAyahAudioSource?> _resolveBasmalah(String reciterId) async {
    const basmalah = ParamAyahRef(surah: 1, ayah: 1);
    final res = await _resolve(basmalah, reciterId);
    return res.fold<EAyahAudioSource?>((failure) {
      AppLogger.warning(
        'Resolve basmalah failed: ${failure.message}',
        tag: 'CBAudioPlayer',
      );
      return null;
    }, (s) => s);
  }

  /// The platform moved to playlist entry [index]. Updates the current ayah,
  /// honours an armed boundary sleep, and counts a repeat pass when the
  /// playlist loops back on itself.
  void _onPlaylistIndexChanged(int? index) {
    if (index == null || index < 0 || index >= _tracks.length) return;
    final previous = _trackIndex;
    _trackIndex = index;
    if (previous == index) return;

    final track = _tracks[index];

    // The entry we just left has finished. A boundary sleep is checked here
    // rather than on `completed`, which now only fires at the end of the whole
    // playlist.
    if (previous != null && previous < _tracks.length) {
      final done = _tracks[previous];
      if (_stopAtBoundary != null && _shouldStopAfter(done)) {
        _stopAtBoundary = null;
        unawaited(stop());
        return;
      }
      // Either the next laid-out copy of the unit, or an infinite repeat
      // looping the playlist — one full pass just finished.
      if (track.pass != done.pass || index < previous) {
        if (_onPassCompleted()) return;
      }
    }

    emit(
      state.copyWith(queueIndex: track.queueIndex, currentAyah: track.ref),
    );
    unawaited(_prefetch(track.queueIndex + 1));
  }

  /// True when playback should stop now that [done] has finished, under the
  /// armed sleep mode. The basmalah lead-in is not an ayah, so it never ends a
  /// boundary.
  bool _shouldStopAfter(_Track done) {
    if (done.isBasmalah) return false;
    if (_stopAtBoundary == ESleepTimer.endOfAyah) return true;
    if (_stopAtBoundary != ESleepTimer.endOfSurah) return false;
    final total = _activeSurah?.totalAyah;
    return total != null && done.ref.ayah >= total;
  }

  /// One pass of the repeat unit finished inside the running playlist. Returns
  /// true when that exhausted the repeat count and playback ended here, so the
  /// caller stops handling the index change.
  ///
  /// Checked per pass rather than per playlist so lowering the count mid-repeat
  /// takes effect at the next seam instead of after the laid-out copies.
  bool _onPassCompleted() {
    _completedPasses++;
    final target = state.options.repeatCount;
    if (target == 0 || _completedPasses < target) return false;
    if (state.options.afterRepeat == EAfterRepeat.continueNext) {
      unawaited(_advanceAfterRepeat());
    } else {
      unawaited(stop());
    }
    return true;
  }

  /// Best-effort background download of the ayah at [queueIndex] so a later
  /// replay is local. It does not affect the playlist already handed to the
  /// platform — that one keeps streaming whatever it started with.
  Future<void> _prefetch(int queueIndex) async {
    if (state.options.repeatMode == RepeatMode.singleAyah) return;
    final queue = state.queue;
    if (queueIndex < 0 || queueIndex >= queue.length) return;
    await _ensure(queue[queueIndex], _activeReciterId ?? 'alafasy');
  }

  /// The playlist ran out. With repeat off that is the end of the unit; with a
  /// finite repeat it means every laid-out pass has played.
  void _onPlaylistCompleted() {
    AppLogger.info(
      'playlist completed passes=$_completedPasses '
      'repeat=${state.options.repeatMode.name}',
      tag: 'CBAudioPlayer',
    );
    // A boundary sleep armed for the final ayah has nothing left to wait for.
    if (_stopAtBoundary != null) {
      _stopAtBoundary = null;
      unawaited(stop());
      return;
    }
    if (state.options.repeatMode == RepeatMode.off) {
      unawaited(_advanceToNextSurahOrStop());
      return;
    }
    _onUnitCompleted();
  }

  /// The playlist's final pass finished. Replays the unit while passes remain
  /// (a repeat count too large to lay out in one playlist), then stops or
  /// advances per [EPlaybackOptions.afterRepeat].
  void _onUnitCompleted() {
    _completedPasses++;
    final target = state.options.repeatCount;
    if (target == 0 || _completedPasses < target) {
      unawaited(_replayUnit());
      return;
    }
    if (state.options.afterRepeat == EAfterRepeat.continueNext) {
      unawaited(_advanceAfterRepeat());
    } else {
      emit(state.copyWith(status: PlayerStatus.completed));
    }
  }

  /// Restarts the playlist from its first entry, keeping the pass tally.
  Future<void> _replayUnit() async {
    try {
      // Deliberate restart, not a lap of the playlist: forget the cursor so the
      // jump back to entry 0 is not counted as another pass.
      _trackIndex = null;
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    } catch (e, st) {
      AppLogger.error(
        'replayUnit failed',
        error: e,
        stackTrace: st,
        tag: 'CBAudioPlayer',
      );
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
      // An explicit tap outside an active repeat-range cancels the range so the
      // tapped ayah actually plays (rather than re-looping the old block).
      final opts = state.options;
      if (opts.repeatMode == RepeatMode.range) {
        final from = opts.rangeFrom;
        final to = opts.rangeTo;
        final inRange =
            from != null &&
            to != null &&
            ref.surah == from.surah &&
            ref.ayah >= from.ayah &&
            ref.ayah <= to.ayah;
        if (!inRange) {
          emit(
            state.copyWith(options: opts.copyWith(repeatMode: RepeatMode.off)),
          );
        }
      }
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
    _tracks = const [];
    _trackIndex = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _stopAtBoundary = null;
    await _player.stop();
    AudioFocus.instance.release(this);
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
    final idx = _trackIndex;
    if (idx == null || idx + 1 >= _tracks.length) return;
    // A jump the user asked for is not an entry running out: forget the cursor
    // so it counts no repeat pass and ends no sleep-timer boundary.
    _trackIndex = null;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    final idx = _trackIndex;
    if (idx == null) return;
    // Restart the current ayah if we're well into it, otherwise step back.
    if (idx == 0 || state.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      if (!_player.playing) await _player.play();
      return;
    }
    _trackIndex = null; // see [next]
    await _player.seekToPrevious();
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
  /// boundary (handled in [_onPlaylistIndexChanged]) and beat an active repeat.
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

  Stream<ParamAyahRef?> get currentAyahStream =>
      stream.map((s) => s.currentAyah).distinct((a, b) => a?.key == b?.key);

  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _errSub?.cancel();
    await _idxSub?.cancel();
    await _noisySub?.cancel();
    await _interruptSub?.cancel();
    _sleepTimer?.cancel();
    AudioFocus.instance.unregister(this);
    await _player.dispose();
    return super.close();
  }
}

/// One clip in the playlist handed to the platform.
class _Track {
  const _Track({
    required this.queueIndex,
    required this.ref,
    required this.source,
    this.pass = 0,
    this.isBasmalah = false,
  });

  _Track onPass(int pass) => _Track(
    queueIndex: queueIndex,
    ref: ref,
    source: source,
    pass: pass,
    isBasmalah: isBasmalah,
  );

  /// Which laid-out copy of the repeat unit this clip belongs to. A change
  /// between two adjacent entries marks one full pass of the unit.
  final int pass;

  /// Index into `SAudioPlayer.queue` of the ayah this clip belongs to. A
  /// basmalah lead-in carries the index of the ayah it introduces, so the
  /// reader highlights that ayah while the lead-in plays.
  final int queueIndex;

  final ParamAyahRef ref;
  final AudioSource source;

  /// True for a basmalah lead-in — an entry that is not an ayah of its own, so
  /// it ends no sleep-timer boundary.
  final bool isBasmalah;
}
