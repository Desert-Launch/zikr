import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';

/// Which rung of the fallback ladder produced a playable source.
///
/// Surfaced to the UI rather than kept internal: playing a different reader's
/// voice without saying so would be a small lie every time the preferred
/// reader has nothing for this dhikr.
enum EAzkarResolutionStage {
  /// Preferred reader, file already on disk. Works offline.
  preferredLocal,

  /// Preferred reader, streaming from source.
  preferredRemote,

  /// A different reader, already downloaded.
  fallbackLocal,

  /// A different reader, streaming from source.
  fallbackRemote,

  /// Audio exists but this device is offline and none of it is downloaded.
  offlineUnavailable,

  /// No reader has a recording of this dhikr at all.
  none;

  bool get isPlayable =>
      this == preferredLocal ||
      this == preferredRemote ||
      this == fallbackLocal ||
      this == fallbackRemote;

  bool get isLocal => this == preferredLocal || this == fallbackLocal;

  /// True when the audio comes from someone other than the chosen reader.
  bool get isFallbackReader => this == fallbackLocal || this == fallbackRemote;
}

/// A resolved, playable (or explicitly unplayable) audio source for one dhikr
/// or one whole-sitting recording.
class EAzkarAudioSource extends Equatable {
  const EAzkarAudioSource({
    required this.stage,
    this.audio,
    this.reader,
    this.uri,
  });

  /// Nothing anywhere for this dhikr.
  const EAzkarAudioSource.none()
    : stage = EAzkarResolutionStage.none,
      audio = null,
      reader = null,
      uri = null;

  /// Audio exists, but it is not on disk and there is no connection.
  const EAzkarAudioSource.offline({this.audio, this.reader})
    : stage = EAzkarResolutionStage.offlineUnavailable,
      uri = null;

  final EAzkarResolutionStage stage;
  final MAzkarAudio? audio;
  final MAzkarReader? reader;

  /// A local file path when [stage] is local, otherwise the remote URL.
  final String? uri;

  bool get isPlayable => stage.isPlayable && (uri?.isNotEmpty ?? false);
  bool get isLocal => stage.isLocal;
  bool get isFallbackReader => stage.isFallbackReader;

  @override
  List<Object?> get props => [stage, audio?.id, reader?.id, uri];
}
