import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_resolve_ayah_source.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_active_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class CBReciter extends Cubit<SReciter> {
  CBReciter({
    required UCGetReciters getReciters,
    required UCSetActiveReciter setActive,
    required UCResolveAyahSource resolve,
    required CBAudioPlayer audioPlayer,
  }) : _getReciters = getReciters,
       _setActive = setActive,
       _resolve = resolve,
       _audioPlayer = audioPlayer,
       super(const SReciter()) {
    AudioFocus.instance.register(this, stopPreview);
  }

  final UCGetReciters _getReciters;
  final UCSetActiveReciter _setActive;
  final UCResolveAyahSource _resolve;
  final CBAudioPlayer _audioPlayer;

  /// What every reciter is auditioned with: the opening of Al-Fatiha, which
  /// every listener knows and every catalogue folder carries.
  static const ParamAyahRef _sample = ParamAyahRef(surah: 1, ayah: 1);

  /// Lazily created so constructing this cubit never spawns a second just_audio
  /// player — just_audio_background allows only one. Built on first preview use.
  AudioPlayer? _previewPlayer;
  StreamSubscription<PlayerState>? _previewSub;

  /// Bumped whenever a preview starts or stops, so a slow load that finishes
  /// after the user has moved on — to another reciter, or away — is dropped
  /// instead of reviving a preview they already left.
  int _previewToken = 0;

  AudioPlayer get _preview {
    final existing = _previewPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _previewSub = player.playerStateStream.listen(_onPreviewState);
    return _previewPlayer = player;
  }

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final listRes = await _getReciters();
    final activeRes = await _getReciters.active();
    listRes.fold(
      (failure) => emit(
        state.copyWith(status: LoadStatus.error, error: failure.message),
      ),
      (list) => emit(
        state.copyWith(
          status: LoadStatus.success,
          all: list,
          activeId: activeRes.fold((_) => list.first.id, (r) => r.id),
        ),
      ),
    );
  }

  /// Persists [id] as the active reciter and hands it to the player, which
  /// rebuilds a running session in the new voice right away.
  Future<void> setActiveReciter(String id) async {
    if (state.activeId == id) return;
    final r = await _setActive(id);
    if (r.isLeft()) return;
    emit(state.copyWith(activeId: id));
    // A running preview holds the shared media slot; free it first so the
    // player's rebuild is not fighting it for the platform.
    if (state.previewingId != null) await stopPreview();
    await _audioPlayer.setReciter(id);
  }

  /// Starts [reciterId]'s sample, or stops it when it is the one playing.
  Future<void> togglePreview(String reciterId) =>
      state.previewingId == reciterId ? stopPreview() : previewAyah(reciterId);

  /// Plays [reciterId]'s sample once — from disk when that reciter's audio is
  /// downloaded, otherwise streamed. The state clears itself when the clip
  /// ends; a failure clears it too and bumps [SReciter.previewFailures].
  Future<void> previewAyah(String reciterId) async {
    final reciter = state.all.where((r) => r.id == reciterId).firstOrNull;
    if (reciter == null) return;
    final token = ++_previewToken;
    emit(
      state.copyWith(clearPreviewing: true).copyWith(
        previewingId: reciterId,
        previewLoading: true,
      ),
    );
    try {
      final source = (await _resolve(_sample, reciterId)).fold(
        (failure) => throw StateError(failure.message),
        (s) => s,
      );
      if (token != _previewToken) return;
      // Free the shared just_audio_background slot from any other domain player
      // (Qur'an audio/radio/adhan) before loading.
      await AudioFocus.instance.take(this);
      final player = _preview;
      await player.setAudioSource(
        AudioSource.uri(
          source.isLocal ? Uri.file(source.uri) : Uri.parse(source.uri),
          // just_audio_background rejects any source without a MediaItem tag.
          tag: MediaItem(
            id: 'reciter_preview_${reciter.id}',
            album: 'reciter_picker_preview'.tr(),
            title: reciter.arabic.isNotEmpty ? reciter.arabic : reciter.name,
            artUri: MediaArtwork.uri,
          ),
        ),
      );
      if (token != _previewToken) return;
      // Not awaited: play() only completes once playback stops. Completion is
      // picked up by [_onPreviewState].
      unawaited(player.play());
    } catch (e, st) {
      // A newer preview (or a stop) superseded this one — its own load
      // interruption is expected, not a failure.
      if (token != _previewToken) return;
      AppLogger.error(
        'Reciter preview failed ($reciterId)',
        error: e,
        stackTrace: st,
        tag: 'CBReciter',
      );
      await stopPreview();
      emit(state.copyWith(previewFailures: state.previewFailures + 1));
    }
  }

  /// Tracks the sample's progress: buffering shows as loading, the clip length
  /// arrives once it is ready, and reaching the end resets the tile.
  void _onPreviewState(PlayerState ps) {
    if (isClosed || state.previewingId == null) return;
    switch (ps.processingState) {
      case ProcessingState.completed:
        unawaited(stopPreview());
      case ProcessingState.ready when ps.playing:
        emit(
          state.copyWith(
            previewLoading: false,
            previewDuration: _previewPlayer?.duration,
          ),
        );
      case ProcessingState.loading || ProcessingState.buffering:
        emit(state.copyWith(previewLoading: true));
      case _:
        break;
    }
  }

  /// Stops any sample and gives the shared media slot back. Safe to call when
  /// nothing is playing — the picker calls it unconditionally on the way out.
  Future<void> stopPreview() async {
    _previewToken++;
    try {
      await _previewPlayer?.stop();
    } catch (e) {
      AppLogger.warning('Reciter preview stop failed: $e', tag: 'CBReciter');
    }
    AudioFocus.instance.release(this);
    if (!isClosed && state.previewingId != null) {
      emit(state.copyWith(clearPreviewing: true));
    }
  }

  @override
  Future<void> close() async {
    AudioFocus.instance.unregister(this);
    await _previewSub?.cancel();
    await _previewPlayer?.dispose();
    return super.close();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
