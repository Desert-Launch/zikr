import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_active_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class CBReciter extends Cubit<SReciter> {
  CBReciter({
    required UCGetReciters getReciters,
    required UCSetActiveReciter setActive,
    required DSRemoteAudio remote,
    required CBAudioPlayer audioPlayer,
  }) : _getReciters = getReciters,
       _setActive = setActive,
       _remote = remote,
       _audioPlayer = audioPlayer,
       super(const SReciter()) {
    AudioFocus.instance.register(this, stopPreview);
  }

  final UCGetReciters _getReciters;
  final UCSetActiveReciter _setActive;
  final DSRemoteAudio _remote;
  final CBAudioPlayer _audioPlayer;

  /// Lazily created so constructing this cubit never spawns a second just_audio
  /// player — just_audio_background allows only one. Built on first preview use.
  AudioPlayer? _previewPlayer;
  AudioPlayer get _preview => _previewPlayer ??= AudioPlayer();

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

  Future<void> setActiveReciter(String id) async {
    final r = await _setActive(id);
    r.fold((_) {}, (_) {
      emit(state.copyWith(activeId: id));
      _audioPlayer.setReciter(id);
    });
  }

  Future<void> previewAyah(String reciterId) async {
    final reciter = state.all.where((r) => r.id == reciterId).firstOrNull;
    if (reciter == null) return;
    final url = _remote.primaryUrl(folder: reciter.folder, surah: 1, ayah: 1);
    try {
      emit(state.copyWith(previewingId: reciterId));
      // Free the shared just_audio_background slot from any other domain player
      // (Qur'an audio/radio/adhan) before previewing.
      await AudioFocus.instance.take(this);
      await _preview.stop();
      await _preview.setUrl(url);
      await _preview.play();
      // Auto-clear after ~7s.
      await Future<void>.delayed(const Duration(seconds: 7));
      await stopPreview();
    } catch (_) {
      await stopPreview();
    }
  }

  Future<void> stopPreview() async {
    await _previewPlayer?.stop();
    AudioFocus.instance.release(this);
    emit(state.copyWith(clearPreviewing: true));
  }

  @override
  Future<void> close() async {
    AudioFocus.instance.unregister(this);
    await _previewPlayer?.dispose();
    return super.close();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
