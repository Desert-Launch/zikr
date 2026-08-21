import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_get_azkar_readers.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_resolve_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_set_preferred_azkar_reader.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio.dart';

/// App-wide adhkar audio player.
///
/// A singleton, so a recitation keeps playing while the user moves between the
/// counter, the category list and the download manager — and so the preferred
/// reader is one value, not one per screen.
///
/// It never touches the counter: tapping play does not advance a repetition and
/// finishing a track does not either. Counting stays exactly where it was, in
/// [CBAzkarSession].
class CBAzkarAudio extends Cubit<SAzkarAudio> {
  CBAzkarAudio({
    required UCGetAzkarReaders readers,
    required UCResolveAzkarAudio resolve,
    required UCSetPreferredAzkarReader preferredReader,
    required DSLocalAzkarAudio manifest,
    AudioPlayer? player,
  }) : _readers = readers,
       _resolve = resolve,
       _preferredReader = preferredReader,
       _manifest = manifest,
       _player = player ?? AudioPlayer(),
       super(const SAzkarAudio()) {
    AudioFocus.instance.register(this, stop);
    _wire();
  }

  final UCGetAzkarReaders _readers;
  final UCResolveAzkarAudio _resolve;
  final UCSetPreferredAzkarReader _preferredReader;
  final DSLocalAzkarAudio _manifest;
  final AudioPlayer _player;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlaybackEvent>? _errorSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptSub;
  bool _resumeAfterInterruption = false;
  bool _catalogueLoaded = false;

  static const String _tag = 'CBAzkarAudio';

  /// Playhead of the loaded track — a stream, not state, so the seek bar can
  /// rebuild several times a second without dragging every other listener with
  /// it.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  // ---------------------------------------------------------------------------
  // Catalogue
  // ---------------------------------------------------------------------------

  /// Loads the reader list and the saved preference. Cheap and idempotent —
  /// only `readers.json` is parsed here, not the mapping files.
  Future<void> loadCatalogue() async {
    if (_catalogueLoaded) return;
    _catalogueLoaded = true;
    final result = await _readers();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (list) => emit(
        state.copyWith(
          readers: list,
          preferredReaderId: _preferredReader.current,
          clearError: true,
        ),
      ),
    );
  }

  /// Works out which adhkar *any* reader recites, so a play button only appears
  /// where tapping it would produce sound.
  ///
  /// This is the one place that parses every mapping file, and it runs when a
  /// user opens an adhkar screen — not at boot. Idempotent: the second screen
  /// to ask gets the cached answer. The set is global rather than per-category
  /// so the favourites list, which spans categories, works from the same data.
  Future<void> prepareAudioIndex() async {
    await loadCatalogue();
    if (state.isIndexReady) return;
    try {
      final indexes = await _manifest.loadAll();
      final withAudio = <String>{};
      final withRecording = <String>{};
      for (final index in indexes.values) {
        for (final entry in index.entries) {
          if (entry.isCategoryRecording) {
            withRecording.addAll(entry.categoryIds);
            continue;
          }
          final id = entry.adhkarId;
          if (id != null) withAudio.add(id);
        }
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          adhkarWithAudio: withAudio,
          categoriesWithRecording: withRecording,
          isIndexReady: true,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to prepare the adhkar audio index',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> setPreferredReader(String? readerId) async {
    final result = await _preferredReader(readerId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(
        readerId == null
            ? state.copyWith(clearPreferred: true, clearError: true)
            : state.copyWith(preferredReaderId: readerId, clearError: true),
      ),
    );
  }

  /// Readers that actually have this dhikr — what the in-player picker lists.
  Future<List<MAzkarReader>> readersForAdhkar(String adhkarId) async {
    final result = await _readers.forAdhkar(adhkarId);
    return result.fold((_) => const <MAzkarReader>[], (list) => list);
  }

  Future<List<MAzkarReader>> readersForCategory(String categoryId) async {
    final result = await _readers.forCategory(categoryId);
    return result.fold((_) => const <MAzkarReader>[], (list) => list);
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Play/pause a single dhikr. Tapping the dhikr that is already loaded
  /// toggles it rather than restarting from the beginning.
  Future<void> toggleAdhkar(
    String adhkarId, {
    required String title,
    String? forceReaderId,
  }) async {
    if (state.isActiveAdhkar(adhkarId) && forceReaderId == null) {
      await _togglePlayPause();
      return;
    }
    await _load(
      title: title,
      adhkarId: adhkarId,
      resolve: () => _resolve(adhkarId, forceReaderId: forceReaderId),
    );
  }

  /// Play/pause a whole-sitting recording.
  Future<void> toggleCategory(
    String categoryId, {
    required String title,
    String? forceReaderId,
  }) async {
    if (state.isActiveCategory(categoryId) && forceReaderId == null) {
      await _togglePlayPause();
      return;
    }
    await _load(
      title: title,
      categoryId: categoryId,
      resolve: () => _resolve.category(categoryId, forceReaderId: forceReaderId),
    );
  }

  Future<void> _load({
    required String title,
    required Future<Either<Failure, EAzkarAudioSource>> Function() resolve,
    String? adhkarId,
    String? categoryId,
  }) async {
    await loadCatalogue();
    // Clear first: switching from a dhikr to a whole-sitting recording passes a
    // null adhkarId, and copyWith would otherwise keep the old one — leaving
    // two tracks looking active at once.
    emit(
      state.copyWith(clearActive: true).copyWith(
        status: AzkarAudioStatus.loading,
        activeAdhkarId: adhkarId,
        activeCategoryId: categoryId,
        clearError: true,
      ),
    );

    final result = await resolve();
    if (isClosed) return;

    final source = result.fold<EAzkarAudioSource?>(
      (failure) {
        emit(
          state.copyWith(
            status: AzkarAudioStatus.error,
            error: failure.message,
          ),
        );
        return null;
      },
      (value) => value,
    );
    if (source == null) return;

    if (!source.isPlayable) {
      emit(
        state.copyWith(
          status: source.stage == EAzkarResolutionStage.offlineUnavailable
              ? AzkarAudioStatus.unavailable
              : AzkarAudioStatus.idle,
          source: source,
        ),
      );
      return;
    }

    emit(state.copyWith(source: source));
    try {
      // Free the shared background-audio slot from the Qur'an player, the radio
      // or an adhan preview before claiming it.
      await AudioFocus.instance.take(this);
      final uri = source.uri ?? '';
      await _player.setAudioSource(
        AudioSource.uri(
          source.isLocal ? Uri.file(uri) : Uri.parse(uri),
          tag: MediaItem(
            id: source.audio?.id ?? (adhkarId ?? categoryId ?? 'azkar'),
            album: source.reader?.nameAr ?? 'الأذكار',
            title: title,
            artist: source.reader?.nameAr ?? '',
            artUri: MediaArtwork.uri,
          ),
        ),
      );
      await _player.play();
    } catch (e, st) {
      AppLogger.error(
        'Adhkar audio playback failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      if (isClosed) return;
      emit(
        state.copyWith(status: AzkarAudioStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      // Restart a finished track rather than sitting at its end doing nothing.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration to) => _player.seek(to);

  Future<void> stop() async {
    await _player.stop();
    AudioFocus.instance.release(this);
    if (isClosed) return;
    emit(state.copyWith(status: AzkarAudioStatus.idle, clearActive: true));
  }

  void _wire() {
    _stateSub = _player.playerStateStream.listen((playerState) {
      if (isClosed) return;
      // Nothing is loaded — don't paint a player over an untouched screen.
      if (state.activeAdhkarId == null && state.activeCategoryId == null) return;
      final AzkarAudioStatus next;
      switch (playerState.processingState) {
        case ProcessingState.idle:
          next = AzkarAudioStatus.idle;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          next = AzkarAudioStatus.loading;
        case ProcessingState.ready:
          next = playerState.playing
              ? AzkarAudioStatus.playing
              : AzkarAudioStatus.paused;
        case ProcessingState.completed:
          next = AzkarAudioStatus.completed;
      }
      if (next != state.status) emit(state.copyWith(status: next));
    });

    // just_audio 0.9.x surfaces playback errors on the event stream's error
    // channel (there is no dedicated errorStream before 0.10).
    _errorSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        AppLogger.warning('Adhkar audio stream error: $e', tag: _tag);
        if (isClosed) return;
        emit(
          state.copyWith(status: AzkarAudioStatus.error, error: e.toString()),
        );
      },
    );

    unawaited(_configureSession());
  }

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _interruptSub = session.interruptionEventStream.listen(_onInterruption);
    } catch (e, st) {
      AppLogger.error(
        'audio_session configure',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      _resumeAfterInterruption = _player.playing;
      if (_resumeAfterInterruption) await _player.pause();
      return;
    }
    if (event.type == AudioInterruptionType.pause &&
        _resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      await _player.play();
    } else {
      _resumeAfterInterruption = false;
    }
  }

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _errorSub?.cancel();
    await _interruptSub?.cancel();
    AudioFocus.instance.unregister(this);
    await _player.dispose();
    return super.close();
  }
}
