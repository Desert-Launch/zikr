import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';

/// Looks up this reader's recording of a given dhikr (or category), or null.
typedef AzkarAudioLookup = MAzkarAudio? Function(String readerId);

/// True when [audio] is fully downloaded on this device.
typedef AzkarDownloadedCheck = bool Function(MAzkarAudio audio);

/// Resolves *which* recording to play, deterministically.
///
/// The ladder, in order:
///   1. preferred reader, downloaded  → offline-capable, exactly what was asked
///   2. preferred reader, streamed
///   3. any other reader, downloaded  → still works with no connection
///   4. any other reader, streamed
///   5. nothing
///
/// Rungs 3 and 4 are marked as fallbacks so the UI can name the voice the user
/// is actually hearing. Order among "other" readers follows the manifest, which
/// is stable across runs — the same dhikr always falls back the same way.
class AzkarAudioResolver {
  const AzkarAudioResolver();

  EAzkarAudioSource resolve({
    required String? preferredReaderId,
    required List<MAzkarReader> readers,
    required AzkarAudioLookup lookup,
    required AzkarDownloadedCheck isDownloaded,
    required String Function(MAzkarAudio audio) localPathOf,
    bool isOnline = true,
  }) {
    if (readers.isEmpty) return const EAzkarAudioSource.none();

    final preferred = _readerById(readers, preferredReaderId);
    final others = readers
        .where((r) => r.id != preferred?.id)
        .toList(growable: false);

    // 1 — preferred reader, on disk.
    final preferredAudio = preferred == null ? null : lookup(preferred.id);
    if (preferred != null &&
        preferredAudio != null &&
        isDownloaded(preferredAudio)) {
      return EAzkarAudioSource(
        stage: EAzkarResolutionStage.preferredLocal,
        audio: preferredAudio,
        reader: preferred,
        uri: localPathOf(preferredAudio),
      );
    }

    // Find a downloaded substitute up front. It is *used* below rung 2 while
    // online — the chosen sheikh outranks a substitute — but offline it is the
    // only thing that can play, so it has to be known before that branch.
    MAzkarAudio? fallbackDownloaded;
    MAzkarReader? fallbackDownloadedReader;
    for (final reader in others) {
      final audio = lookup(reader.id);
      if (audio != null && isDownloaded(audio)) {
        fallbackDownloaded = audio;
        fallbackDownloadedReader = reader;
        break;
      }
    }

    if (!isOnline) {
      if (fallbackDownloaded != null) {
        return EAzkarAudioSource(
          stage: EAzkarResolutionStage.fallbackLocal,
          audio: fallbackDownloaded,
          reader: fallbackDownloadedReader,
          uri: localPathOf(fallbackDownloaded),
        );
      }
      final known = preferredAudio ?? _firstAvailable(others, lookup);
      if (known == null) return const EAzkarAudioSource.none();
      return EAzkarAudioSource.offline(
        audio: known,
        reader: preferredAudio != null ? preferred : null,
      );
    }

    // 2 — preferred reader, streamed.
    if (preferred != null && preferredAudio != null) {
      return EAzkarAudioSource(
        stage: EAzkarResolutionStage.preferredRemote,
        audio: preferredAudio,
        reader: preferred,
        uri: preferredAudio.remoteUrl,
      );
    }

    if (fallbackDownloaded != null) {
      return EAzkarAudioSource(
        stage: EAzkarResolutionStage.fallbackLocal,
        audio: fallbackDownloaded,
        reader: fallbackDownloadedReader,
        uri: localPathOf(fallbackDownloaded),
      );
    }

    // 4 — another reader, streamed.
    for (final reader in others) {
      final audio = lookup(reader.id);
      if (audio == null) continue;
      return EAzkarAudioSource(
        stage: EAzkarResolutionStage.fallbackRemote,
        audio: audio,
        reader: reader,
        uri: audio.remoteUrl,
      );
    }

    return const EAzkarAudioSource.none();
  }

  MAzkarReader? _readerById(List<MAzkarReader> readers, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final r in readers) {
      if (r.id == id) return r;
    }
    return null;
  }

  MAzkarAudio? _firstAvailable(
    List<MAzkarReader> readers,
    AzkarAudioLookup lookup,
  ) {
    for (final r in readers) {
      final hit = lookup(r.id);
      if (hit != null) return hit;
    }
    return null;
  }
}
