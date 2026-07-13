/// A playable audio source for a single ayah, resolved offline-first: a local
/// file when the ayah is already on disk, otherwise a remote CDN URL to stream.
class EAyahAudioSource {
  const EAyahAudioSource({required this.uri, required this.isLocal});

  /// A filesystem path (when [isLocal]) or an `https` URL (when streaming).
  final String uri;

  /// True when [uri] is a downloaded file on disk; false when it must be
  /// streamed from the network.
  final bool isLocal;
}
