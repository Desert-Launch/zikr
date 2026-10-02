import 'package:audio_service/audio_service.dart';

/// The browsable catalogue the media session offers to a car head unit
/// (Android Auto today, CarPlay later) and to voice search.
///
/// The session ([AppAudioHandler]) lives in core and knows nothing about Qur'an
/// or radio; the feature that composes them implements this and attaches it
/// once the app's DI is up.
abstract class MediaLibrary {
  /// The items under [parentId]: [AudioService.browsableRootId] for the top
  /// level, [AudioService.recentRootId] for the "resume" slot, otherwise an id
  /// this library handed out earlier.
  Future<List<MediaItem>> children(String parentId);

  /// The item with [mediaId], or null when the id is unknown.
  Future<MediaItem?> item(String mediaId);

  /// Starts playing the playable item [mediaId]. Unknown ids are ignored.
  Future<void> play(String mediaId);

  /// Plays the best match for a spoken or typed [query]. An empty query is
  /// the user asking for "something" — the library picks.
  Future<void> playFromSearch(String query);

  /// The playable items matching [query], for the head unit's search screen.
  Future<List<MediaItem>> search(String query);
}
