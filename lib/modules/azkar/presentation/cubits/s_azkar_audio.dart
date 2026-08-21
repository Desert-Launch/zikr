import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';

enum AzkarAudioStatus {
  idle,
  loading,
  playing,
  paused,
  completed,

  /// Audio exists but cannot be reached right now (offline, nothing on disk).
  unavailable,
  error,
}

/// State of the app-wide adhkar audio player.
///
/// Deliberately free of position/duration: those tick several times a second
/// and would rebuild every listener. The cubit exposes them as streams instead,
/// so only the seek bar rebuilds.
class SAzkarAudio extends Equatable {
  const SAzkarAudio({
    this.status = AzkarAudioStatus.idle,
    this.readers = const <MAzkarReader>[],
    this.preferredReaderId,
    this.activeAdhkarId,
    this.activeCategoryId,
    this.source,
    this.adhkarWithAudio = const <String>{},
    this.categoriesWithRecording = const <String>{},
    this.isIndexReady = false,
    this.error,
  });

  final AzkarAudioStatus status;

  /// Every verified reader in the manifest.
  final List<MAzkarReader> readers;

  /// The user's global choice, or null when they have not picked one.
  final String? preferredReaderId;

  /// What is loaded into the player right now.
  final String? activeAdhkarId;
  final String? activeCategoryId;

  /// How the active audio was resolved — carries the reader actually playing,
  /// which is how the UI can admit to a fallback instead of hiding it.
  final EAzkarAudioSource? source;

  /// Ids of every dhikr some reader recites individually.
  final Set<String> adhkarWithAudio;

  /// Category ids that have at least one whole-sitting recording.
  final Set<String> categoriesWithRecording;

  /// Whether the two sets above have been built yet.
  final bool isIndexReady;

  final String? error;

  bool get isBusy => status == AzkarAudioStatus.loading;

  bool get isPlaying => status == AzkarAudioStatus.playing;

  /// True while this exact dhikr is the loaded track (playing *or* paused), so
  /// the button can show pause without losing its place.
  bool isActiveAdhkar(String adhkarId) =>
      activeAdhkarId == adhkarId && status != AzkarAudioStatus.idle;

  bool isPlayingAdhkar(String adhkarId) =>
      activeAdhkarId == adhkarId && status == AzkarAudioStatus.playing;

  bool isActiveCategory(String categoryId) =>
      activeCategoryId == categoryId && status != AzkarAudioStatus.idle;

  bool isPlayingCategory(String categoryId) =>
      activeCategoryId == categoryId && status == AzkarAudioStatus.playing;

  bool hasAudioFor(String adhkarId) => adhkarWithAudio.contains(adhkarId);

  bool hasCategoryRecording(String categoryId) =>
      categoriesWithRecording.contains(categoryId);

  /// The reader whose voice is actually loaded, which is not always the
  /// preferred one.
  MAzkarReader? get playingReader => source?.reader;

  /// True when the loaded audio is someone other than the preferred reader.
  bool get isFallbackReader => source?.isFallbackReader ?? false;

  MAzkarReader? readerById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final r in readers) {
      if (r.id == id) return r;
    }
    return null;
  }

  MAzkarReader? get preferredReader => readerById(preferredReaderId);

  SAzkarAudio copyWith({
    AzkarAudioStatus? status,
    List<MAzkarReader>? readers,
    String? preferredReaderId,
    String? activeAdhkarId,
    String? activeCategoryId,
    EAzkarAudioSource? source,
    Set<String>? adhkarWithAudio,
    Set<String>? categoriesWithRecording,
    bool? isIndexReady,
    String? error,
    bool clearError = false,
    bool clearActive = false,
    bool clearPreferred = false,
  }) {
    return SAzkarAudio(
      status: status ?? this.status,
      readers: readers ?? this.readers,
      preferredReaderId: clearPreferred
          ? null
          : (preferredReaderId ?? this.preferredReaderId),
      activeAdhkarId: clearActive
          ? null
          : (activeAdhkarId ?? this.activeAdhkarId),
      activeCategoryId: clearActive
          ? null
          : (activeCategoryId ?? this.activeCategoryId),
      source: clearActive ? null : (source ?? this.source),
      adhkarWithAudio: adhkarWithAudio ?? this.adhkarWithAudio,
      categoriesWithRecording:
          categoriesWithRecording ?? this.categoriesWithRecording,
      isIndexReady: isIndexReady ?? this.isIndexReady,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    readers,
    preferredReaderId,
    activeAdhkarId,
    activeCategoryId,
    source,
    adhkarWithAudio,
    categoriesWithRecording,
    isIndexReady,
    error,
  ];
}
