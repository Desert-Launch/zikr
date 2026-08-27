import 'dart:io';

import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reciters.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';

/// Pre-downloads the basmalah for **every** reciter on first launch (~1 MB
/// total) so the lead-in before ayah 1 of any surah plays instantly and works
/// offline, whichever reciter the user later picks.
///
/// The basmalah is Al-Fatiha 1:1, so this stores nothing special: it fills the
/// ordinary `{reciter}/001/001.mp3` slot that [DSLocalAudioFiles] already owns,
/// and the player resolves it through the normal ayah resolver.
///
/// Idempotent by disk truth — no "done" flag. A file already on disk is skipped,
/// so a run that was offline (or partial) simply completes on the next cold
/// start, and a reciter deleted from the downloads manager is restored.
class BasmalahBootstrap {
  BasmalahBootstrap({
    required DSLocalReciters catalog,
    required DSLocalAudioFiles files,
    required DSRemoteAudio remote,
    required DSAudioDownloader downloader,
  }) : _catalog = catalog,
       _files = files,
       _remote = remote,
       _downloader = downloader;

  final DSLocalReciters _catalog;
  final DSLocalAudioFiles _files;
  final DSRemoteAudio _remote;
  final DSAudioDownloader _downloader;

  /// The basmalah's own coordinates: Al-Fatiha, ayah 1.
  static const int surah = 1;
  static const int ayah = 1;

  /// Consecutive failures after which the run gives up for this launch —
  /// the device is offline or the CDN is down, and 15 doomed requests on every
  /// cold start help nobody. The next launch retries from scratch.
  static const int _failureBudget = 3;

  Future<void> run() async {
    try {
      final reciters = await _catalog.all();
      var fetched = 0;
      var consecutiveFailures = 0;

      for (final reciter in reciters) {
        final path = await _files.pathFor(reciter.id, surah, ayah);
        if (await File(path).exists()) continue;

        try {
          await _files.ensureDir(reciter.id, surah);
          await _downloader.downloadFile(
            taskId: 'basmalah_${reciter.id}',
            url: _remote.primaryUrl(
              folder: reciter.folder,
              surah: surah,
              ayah: ayah,
            ),
            savePath: path,
          );
          fetched++;
          consecutiveFailures = 0;
        } catch (e) {
          consecutiveFailures++;
          AppLogger.warning(
            'Basmalah for ${reciter.id} failed: $e',
            tag: 'BasmalahBootstrap',
          );
          if (consecutiveFailures >= _failureBudget) {
            AppLogger.warning(
              'Giving up after $consecutiveFailures failures — retrying on the '
              'next launch',
              tag: 'BasmalahBootstrap',
            );
            return;
          }
        }
      }

      if (fetched > 0) {
        AppLogger.info(
          'Basmalah ready for $fetched new reciter(s)',
          tag: 'BasmalahBootstrap',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'Basmalah bootstrap',
        error: e,
        stackTrace: st,
        tag: 'BasmalahBootstrap',
      );
    }
  }
}
