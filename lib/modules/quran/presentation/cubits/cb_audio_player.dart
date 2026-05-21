import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';

/// App-wide audio player. Singleton (registered via Modular.addSingleton).
class CBAudioPlayer extends Cubit<SAudioPlayer> {
  CBAudioPlayer({
    required RAudio audio,
    required RQuran quran,
    required UCGetReciters reciters,
  })  : _audio = audio,
        _quran = quran,
        _reciters = reciters,
        _player = AudioPlayer(),
        super(const SAudioPlayer()) {
    _hydrate();
    _wireStreams();
  }

  final RAudio _audio;
  final RQuran _quran;
  final UCGetReciters _reciters;
  final AudioPlayer _player;

  String? _activeReciterId;
  String? _activeReciterName;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<int?>? _idxSub;

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
      PlayerStatus next;
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
          next = PlayerStatus.completed;
      }
      emit(state.copyWith(status: next));
    });

    _posSub = _player.positionStream.listen((p) => emit(state.copyWith(position: p)));
    _durSub = _player.durationStream.listen((d) {
      emit(state.copyWith(duration: d ?? Duration.zero));
    });
    _idxSub = _player.currentIndexStream.listen((idx) {
      if (idx == null) return;
      final q = state.queue;
      if (idx < 0 || idx >= q.length) return;
      emit(state.copyWith(queueIndex: idx, currentAyah: q[idx]));
    });
  }

  Future<void> setReciter(String reciterId) async {
    _activeReciterId = reciterId;
    emit(state.copyWith(reciterId: reciterId));
  }

  Future<void> playFrom(ParamAyahRef ref, {bool toEndOfSurah = true}) async {
    try {
      emit(state.copyWith(status: PlayerStatus.loading, clearError: true));
      final reciterId = _activeReciterId ??
          (await _reciters.active())
              .fold<String?>((_) => null, (r) => r.id) ?? 'alafasy';
      _activeReciterId = reciterId;

      // Build the ayah queue: from selected ayah to end of surah (or to whatever scope).
      final surahsRes = await _quran.getSurah(ref.surah);
      final surah = surahsRes.fold<MSurah?>((_) => null, (s) => s);
      final endAyah = toEndOfSurah ? (surah?.totalAyah ?? ref.ayah) : ref.ayah;

      final queue = <ParamAyahRef>[];
      for (int a = ref.ayah; a <= endAyah; a++) {
        queue.add(ParamAyahRef(surah: ref.surah, ayah: a));
      }

      // Resolve URLs in parallel.
      final sources = <AudioSource>[];
      for (final ayahRef in queue) {
        final urlRes = await _audio.resolveAyahAudio(
          reciterId: reciterId, surah: ayahRef.surah, ayah: ayahRef.ayah,
        );
        urlRes.fold((failure) {
          AppLogger.warning('Audio resolve failed: ${failure.message}', tag: 'CBAudioPlayer');
        }, (url) {
          final tag = MediaItem(
            id: '${ayahRef.surah}_${ayahRef.ayah}',
            album: 'القرآن الكريم${_activeReciterName != null ? ' - $_activeReciterName' : ''}',
            title: '${surah?.arabic ?? ''} - الآية ${ayahRef.ayah}',
            artist: _activeReciterName ?? '',
          );
          final uri = Uri.parse(url);
          final source = url.startsWith('file://')
              ? AudioSource.uri(uri, tag: tag)
              : LockCachingAudioSource(uri, tag: tag);
          sources.add(source);
        });
      }

      if (sources.isEmpty) {
        emit(state.copyWith(status: PlayerStatus.error, error: 'No audio sources resolved'));
        return;
      }

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist, initialIndex: 0);
      await _player.setSpeed(state.options.speed);
      _applyLoopMode();
      emit(state.copyWith(
        queue: queue,
        queueIndex: 0,
        currentAyah: queue.first,
        reciterId: reciterId,
        status: PlayerStatus.loading,
      ));
      await _player.play();
    } catch (e, st) {
      AppLogger.error('playFrom failed', error: e, stackTrace: st, tag: 'CBAudioPlayer');
      emit(state.copyWith(status: PlayerStatus.error, error: e.toString()));
    }
  }

  Future<void> playRange(ParamAyahRef from, ParamAyahRef to) async {
    try {
      // v1: only supports ranges inside a single surah; cross-surah ranges
      // can be added later by stitching `ayatOfSurah` results.
      if (from.surah != to.surah) {
        AppLogger.warning('Cross-surah ranges not supported yet', tag: 'CBAudioPlayer');
        return;
      }
      final ayatRes = await _quran.ayatOfSurah(from.surah);
      final queue = ayatRes.fold<List<ParamAyahRef>>(
        (_) => [],
        (list) => list.where((r) => r.ayah >= from.ayah && r.ayah <= to.ayah).toList(),
      );
      if (queue.isEmpty) return;
      await playFrom(queue.first, toEndOfSurah: false);
      // Override the queue produced by playFrom with the precise range.
      emit(state.copyWith(queue: queue, queueIndex: 0, currentAyah: queue.first));
    } catch (e, st) {
      AppLogger.error('playRange failed', error: e, stackTrace: st, tag: 'CBAudioPlayer');
    }
  }

  Future<void> repeatSingle(ParamAyahRef ref) async {
    emit(state.copyWith(options: state.options.copyWith(repeatMode: RepeatMode.singleAyah)));
    await playFrom(ref, toEndOfSurah: false);
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() async {
    await _player.stop();
    emit(state.copyWith(
      status: PlayerStatus.idle,
      clearCurrentAyah: true,
      clearQueueIndex: true,
      queue: const [],
    ));
  }
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();
  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) async {
    emit(state.copyWith(options: state.options.copyWith(speed: speed)));
    await _player.setSpeed(speed);
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    emit(state.copyWith(options: state.options.copyWith(repeatMode: mode)));
    _applyLoopMode();
  }

  void _applyLoopMode() {
    switch (state.options.repeatMode) {
      case RepeatMode.off:
        _player.setLoopMode(LoopMode.off);
      case RepeatMode.singleAyah:
        _player.setLoopMode(LoopMode.one);
      case RepeatMode.range:
        _player.setLoopMode(LoopMode.all);
    }
  }

  Stream<ParamAyahRef?> get currentAyahStream =>
      stream.map((s) => s.currentAyah).distinct((a, b) => a?.key == b?.key);

  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _idxSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
