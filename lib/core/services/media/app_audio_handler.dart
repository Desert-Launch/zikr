import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/media_library.dart';
import 'package:quran/core/services/media/media_session_binding.dart';

/// The app's single media session: what the media notification, the lock
/// screen, headset/Bluetooth buttons and Android Auto all talk to.
///
/// The app has several domain players (Qur'an recitation, radio, adhan, azkar,
/// salawat preview) and only one of them plays at a time — [AudioFocus] makes
/// them mutually exclusive. Whichever one holds focus is [bind]-ed here: the
/// session mirrors that player's state, and transport commands are forwarded to
/// it (or to its owner's overrides, see [MediaSessionBinding]).
///
/// The browse tree a car shows comes from a [MediaLibrary] that the car feature
/// attaches once DI is ready ([attachLibrary]); the session itself stays free of
/// any domain knowledge.
///
/// Replaces just_audio_background, which could only mirror one player and had
/// no browsable library.
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler._() {
    // Advertise the browse/search actions from the start, so a head unit or
    // voice assistant can ask for something before anything has played.
    playbackState.add(PlaybackState(systemActions: _systemActions));
  }

  static AppAudioHandler? _instance;

  /// The session, or null when [init] failed — players then still play, just
  /// without notification/lock-screen/car controls.
  static AppAudioHandler? get instance => _instance;

  /// Lets Android Auto list items as rows (it would otherwise tile them in a
  /// grid, which needs artwork for every item) and shows its search button.
  static const Map<String, dynamic> _browsableRootExtras = {
    'android.media.browse.SEARCH_SUPPORTED': true,
    'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
    'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
    'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 1,
  };

  static const Set<MediaAction> _systemActions = {
    MediaAction.seek,
    MediaAction.seekForward,
    MediaAction.seekBackward,
    MediaAction.skipToQueueItem,
    MediaAction.playFromMediaId,
    MediaAction.playFromSearch,
  };

  /// How long a car request may wait for the library to be attached on a cold
  /// start, before answering with an empty list.
  static const Duration _libraryWait = Duration(seconds: 8);

  /// Starts the platform media service. Call once from `main`, before
  /// `runApp`: a car connecting to a killed app boots the engine through this
  /// service, and the session must exist by the time it asks for the root.
  static Future<void> init() async {
    if (_instance != null) return;
    try {
      _instance = await AudioService.init(
        builder: AppAudioHandler._,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.app.quran.audio',
          androidNotificationChannelName: 'Quran Recitation',
          androidNotificationOngoing: true,
          androidBrowsableRootExtras: _browsableRootExtras,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'AudioService.init failed — playing without a media session',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
    }
  }

  Object? _owner;
  MediaSessionBinding? _binding;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// The sequence last published as [queue], to skip republishing on every
  /// index change.
  List<IndexedAudioSource>? _publishedSequence;

  /// Message of the last playback error, shown by the head unit until the
  /// player moves on.
  String? _errorMessage;

  MediaLibrary Function()? _provideLibrary;
  MediaLibrary? _library;
  final Completer<void> _libraryAttached = Completer<void>();

  // ---------------------------------------------------------------------------
  // Binding
  // ---------------------------------------------------------------------------

  /// Points the session at [owner]'s player. A null [binding] (a player that
  /// opts out, like the reciter preview) clears the session instead.
  void bind(Object owner, MediaSessionBinding? binding) {
    if (identical(_owner, owner) && identical(_binding, binding)) return;
    _detach();
    _owner = owner;
    _binding = binding;
    if (binding == null) {
      _publishIdle();
      return;
    }
    final player = binding.player;
    _subs
      ..add(
        player.playbackEventStream.listen(
          (_) => _onPlayerEvent(player),
          onError: (Object e, StackTrace _) => _onPlayerError(player, e),
        ),
      )
      ..add(player.playingStream.listen((_) => _publishState(player)))
      ..add(player.sequenceStateStream.listen(_publishSequence))
      ..add(player.durationStream.listen((_) => _publishCurrentItem()));
    _publishState(player);
    _publishSequence(player.sequenceState);
  }

  /// [owner] gave up focus. Clears the session if it is still showing
  /// [owner]'s player — a handover to another player has already re-bound it.
  void unbind(Object owner) {
    if (!identical(_owner, owner)) return;
    _detach();
    _publishIdle();
  }

  void _detach() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    _owner = null;
    _binding = null;
    _publishedSequence = null;
    _errorMessage = null;
  }

  // ---------------------------------------------------------------------------
  // Mirroring the bound player
  // ---------------------------------------------------------------------------

  void _onPlayerEvent(AudioPlayer player) {
    // Anything past a reload means the player recovered from the error.
    if (player.processingState != ProcessingState.idle) _errorMessage = null;
    _publishState(player);
  }

  void _onPlayerError(AudioPlayer player, Object error) {
    _errorMessage = error is PlayerException
        ? (error.message ?? error.toString())
        : error.toString();
    _publishState(player);
  }

  void _publishState(AudioPlayer player) {
    final playing = player.playing;
    final controls = [
      if (player.hasPrevious) MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      if (player.hasNext) MediaControl.skipToNext,
    ];
    final processing = player.processingState;
    final error = _errorMessage;
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: _systemActions,
        // The compact notification fits three buttons; stop stays in the
        // expanded view.
        androidCompactActionIndices: [
          for (var i = 0; i < controls.length; i++)
            if (controls[i].action != MediaAction.stop) i,
        ],
        processingState: error != null
            ? AudioProcessingState.error
            : _processingStateOf(processing),
        playing:
            playing &&
            processing != ProcessingState.idle &&
            processing != ProcessingState.completed,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
        errorMessage: error,
      ),
    );
  }

  void _publishSequence(SequenceState? sequenceState) {
    if (sequenceState == null) return;
    final sequence = sequenceState.effectiveSequence;
    if (!_isPublished(sequence)) {
      _publishedSequence = sequence;
      queue.add([
        for (final source in sequence)
          if (source.tag case final MediaItem item) item,
      ]);
    }
    _publishCurrentItem();
  }

  /// Same sources in the same order as the queue already published. just_audio
  /// hands out a fresh list on every emission — every ayah change — so identity
  /// alone would resend a playlist of hundreds of entries every few seconds.
  bool _isPublished(List<IndexedAudioSource> sequence) {
    final published = _publishedSequence;
    if (published == null || published.length != sequence.length) return false;
    for (var i = 0; i < sequence.length; i++) {
      if (!identical(published[i], sequence[i])) return false;
    }
    return true;
  }

  /// Publishes the playing entry with the player's current duration. Called
  /// from both the index and the duration streams, each reading the other's
  /// latest value, so whichever fires last publishes a matching pair.
  void _publishCurrentItem() {
    final player = _binding?.player;
    if (player == null) return;
    final tag = player.sequenceState?.currentSource?.tag;
    if (tag is! MediaItem) return;
    final duration = player.duration;
    final item = duration == null ? tag : tag.copyWith(duration: duration);
    final shown = mediaItem.value;
    // Consecutive copies of a repeated ayah carry the same item. (A reciter
    // switch keeps the ayah's id but changes its artist.)
    if (shown != null &&
        shown.id == item.id &&
        shown.title == item.title &&
        shown.artist == item.artist &&
        shown.duration == item.duration) {
      return;
    }
    mediaItem.add(item);
  }

  void _publishIdle() {
    playbackState.add(PlaybackState(systemActions: _systemActions));
    mediaItem.add(null);
    queue.add(const []);
  }

  static AudioProcessingState _processingStateOf(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ---------------------------------------------------------------------------
  // Transport commands (notification, lock screen, headset, car)
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async => _binding?.player.play();

  @override
  Future<void> pause() async => _binding?.player.pause();

  @override
  Future<void> stop() async {
    final binding = _binding;
    if (binding == null) return;
    await binding.onStop();
  }

  @override
  Future<void> seek(Duration position) async =>
      _binding?.player.seek(position);

  @override
  Future<void> skipToNext() async {
    final binding = _binding;
    if (binding == null) return;
    final override = binding.onSkipToNext;
    if (override != null) return override();
    await binding.player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    final binding = _binding;
    if (binding == null) return;
    final override = binding.onSkipToPrevious;
    if (override != null) return override();
    await binding.player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final binding = _binding;
    if (binding == null) return;
    final override = binding.onSkipToQueueItem;
    if (override != null) return override(index);
    await binding.player.seek(Duration.zero, index: index);
  }

  // ---------------------------------------------------------------------------
  // Browsing + voice (Android Auto)
  // ---------------------------------------------------------------------------

  /// Hands the session its browse tree. Called once from the app root, after
  /// DI is up; requests that arrived earlier are waiting on it.
  ///
  /// [provide] is only called on a car's first request, so the players the
  /// library drives are not built for a session that never meets a car.
  void attachLibrary(MediaLibrary Function() provide) {
    _provideLibrary = provide;
    if (!_libraryAttached.isCompleted) _libraryAttached.complete();
  }

  Future<MediaLibrary?> _awaitLibrary() async {
    final built = _library;
    if (built != null) return built;
    if (!_libraryAttached.isCompleted) {
      var attached = true;
      await _libraryAttached.future.timeout(
        _libraryWait,
        onTimeout: () => attached = false,
      );
      if (!attached) return null;
    }
    final provide = _provideLibrary;
    if (provide == null) return null;
    return _library ??= provide();
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    try {
      final library = await _awaitLibrary();
      if (library == null) return const [];
      return await library.children(parentMediaId);
    } catch (e, st) {
      AppLogger.error(
        'getChildren($parentMediaId) failed',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
      return const [];
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    try {
      final library = await _awaitLibrary();
      return await library?.item(mediaId);
    } catch (e, st) {
      AppLogger.error(
        'getMediaItem($mediaId) failed',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
      return null;
    }
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    try {
      final library = await _awaitLibrary();
      await library?.play(mediaId);
    } catch (e, st) {
      AppLogger.error(
        'playFromMediaId($mediaId) failed',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
    }
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    try {
      // "Play <app>" with nothing named resumes what is already loaded.
      final binding = _binding;
      if (query.trim().isEmpty && binding != null) {
        // Not awaited: just_audio's play() completes only once playback stops.
        unawaited(binding.player.play());
        return;
      }
      final library = await _awaitLibrary();
      await library?.playFromSearch(query);
    } catch (e, st) {
      AppLogger.error(
        'playFromSearch failed',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    try {
      final library = await _awaitLibrary();
      if (library == null) return const [];
      return await library.search(query);
    } catch (e, st) {
      AppLogger.error(
        'search failed',
        error: e,
        stackTrace: st,
        tag: 'AppAudioHandler',
      );
      return const [];
    }
  }
}
