import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/entities/ayah_counts.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';
import 'package:quran/modules/quran/domain/services/download_notifier.dart';

/// Tracks one in-flight surah download so concurrent callers (the manager UI
/// and the audio player's background warm) share a single download.
class _ActiveSurahDownload {
  _ActiveSurahDownload(this.controller);
  final StreamController<SurahDownloadProgress> controller;
  bool cancelled = false;
  SurahDownloadProgress? last;
}

class RImplAudioDownloads implements RAudioDownloads {
  RImplAudioDownloads({
    required DSLocalAudioFiles files,
    required DSRemoteAudio remote,
    required DSAudioDownloader downloader,
    required RReciter reciter,
    DownloadNotifier? notifier,
  }) : _files = files,
       _remote = remote,
       _downloader = downloader,
       _reciter = reciter,
       _notifier = notifier;

  final DSLocalAudioFiles _files;
  final DSRemoteAudio _remote;
  final DSAudioDownloader _downloader;
  final RReciter _reciter;
  final DownloadNotifier? _notifier;

  /// Max ayat fetched in parallel per surah — gentle on the free CDN.
  static const int _concurrency = 3;

  final Map<String, _ActiveSurahDownload> _active = {};
  bool _cancelAllRequested = false;

  /// True while a "download all" run is in progress, so the progress
  /// notification isn't dismissed in the brief gap between surahs.
  bool _allActive = false;

  String _key(String reciterId, int surah) => '${reciterId}_$surah';

  Future<MReciter?> _lookupReciter(String id) async {
    final eitherList = await _reciter.getReciters();
    return eitherList.fold<MReciter?>(
      (_) => null,
      (list) => list.where((r) => r.id == id).firstOrNull,
    );
  }

  Future<void> _downloadOne(
    String folder,
    String reciterId,
    int surah,
    int ayah,
  ) async {
    final url = _remote.primaryUrl(folder: folder, surah: surah, ayah: ayah);
    final path = await _files.pathFor(reciterId, surah, ayah);
    final taskId = '${reciterId}_${surah}_$ayah';
    await _downloader.downloadFile(taskId: taskId, url: url, savePath: path);
  }

  Failure _handleDio(DioException e) {
    return Failure.networkFailure(message: e.message ?? 'Network error');
  }

  // ---------------------------------------------------------------------------
  // On-demand single ayah
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, String>> ensureAyahFile(
    String reciterId,
    int surah,
    int ayah,
  ) async {
    try {
      final path = await _files.pathFor(reciterId, surah, ayah);
      if (await File(path).exists()) return Right(path);

      final reciter = await _lookupReciter(reciterId);
      if (reciter == null) {
        return Left(Failure.notFoundFailure(message: 'Reciter $reciterId not found'));
      }
      await _files.ensureDir(reciterId, surah);
      await _downloadOne(reciter.folder, reciterId, surah, ayah);
      return Right(path);
    } on DioException catch (e) {
      return Left(_handleDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAudioDownloads.ensureAyahFile',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Per-surah download (idempotent, shared, cancellable)
  // ---------------------------------------------------------------------------

  @override
  Stream<SurahDownloadProgress> downloadSurah(String reciterId, int surah) {
    final key = _key(reciterId, surah);
    final existing = _active[key];
    if (existing != null) return existing.controller.stream;

    final controller = StreamController<SurahDownloadProgress>.broadcast();
    final active = _ActiveSurahDownload(controller);
    _active[key] = active;
    // Start eagerly; the work runs whether or not anyone subscribes.
    scheduleMicrotask(() => _runSurah(reciterId, surah, active, key));
    return controller.stream;
  }

  void _safeAdd(_ActiveSurahDownload active, SurahDownloadProgress p) {
    active.last = p;
    if (!active.controller.isClosed) active.controller.add(p);
    _notifier?.notifySurahProgress(
      surah: p.surahNumber,
      onDisk: p.onDisk,
      total: p.total,
    );
  }

  Future<void> _runSurah(
    String reciterId,
    int surah,
    _ActiveSurahDownload active,
    String key,
  ) async {
    final total = AyahCounts.forSurah(surah);
    try {
      if (total == 0) return;

      // Pass 1 — discover which ayat are missing.
      final missing = <int>[];
      for (int a = 1; a <= total; a++) {
        if (active.cancelled) return;
        if (!await _files.exists(reciterId, surah, a)) missing.add(a);
      }
      final skipped = total - missing.length;
      var progress = SurahDownloadProgress(
        surahNumber: surah,
        downloaded: 0,
        total: total,
        skipped: skipped,
      );
      _safeAdd(active, progress);
      if (missing.isEmpty) return;

      final reciter = await _lookupReciter(reciterId);
      if (reciter == null) {
        _safeAdd(active, progress.copyWith(error: 'Reciter not found'));
        return;
      }
      await _files.ensureDir(reciterId, surah);

      // Pass 2 — fetch the gaps, [_concurrency] at a time.
      var downloaded = 0;
      String? lastError;
      for (int i = 0; i < missing.length; i += _concurrency) {
        if (active.cancelled) break;
        final chunk = missing.skip(i).take(_concurrency).toList();
        final results = await Future.wait(
          chunk.map((ayah) async {
            try {
              await _downloadOne(reciter.folder, reciterId, surah, ayah);
              return true;
            } catch (e) {
              lastError = e.toString();
              ErrorHelper.printDebugError(
                name: 'RImplAudioDownloads._downloadOne',
                error: e,
              );
              return false;
            }
          }),
        );
        downloaded += results.where((ok) => ok).length;
        progress = SurahDownloadProgress(
          surahNumber: surah,
          downloaded: downloaded,
          total: total,
          skipped: skipped,
          error: lastError,
        );
        _safeAdd(active, progress);
      }
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAudioDownloads._runSurah',
        error: e,
        stackTrace: st,
      );
      final base =
          active.last ??
          SurahDownloadProgress(
            surahNumber: surah,
            downloaded: 0,
            total: total,
            skipped: 0,
          );
      _safeAdd(active, base.copyWith(error: e.toString()));
    } finally {
      _active.remove(key);
      if (!active.controller.isClosed) await active.controller.close();
      if (_active.isEmpty && !_allActive) _notifier?.notifyIdle();
    }
  }

  // ---------------------------------------------------------------------------
  // Download-all
  // ---------------------------------------------------------------------------

  @override
  Stream<AllSurahsDownloadProgress> downloadAllSurahs(String reciterId) async* {
    _cancelAllRequested = false;
    _allActive = true;
    var completed = 0;
    try {
      for (int surah = 1; surah <= AyahCounts.surahCount; surah++) {
        if (_cancelAllRequested) break;
        await for (final p in downloadSurah(reciterId, surah)) {
          yield AllSurahsDownloadProgress(
            currentSurah: surah,
            currentSurahProgress: p,
            completedSurahs: completed,
          );
        }
        completed++;
      }
    } finally {
      _allActive = false;
      if (_active.isEmpty) _notifier?.notifyIdle();
    }
  }

  // ---------------------------------------------------------------------------
  // Disk-truth status
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, SurahDownloadInfo>> surahInfo(
    String reciterId,
    int surah,
  ) async {
    try {
      final total = AyahCounts.forSurah(surah);
      final onDisk = await _files.countDownloaded(reciterId, surah);
      return Right(
        SurahDownloadInfo(
          surahNumber: surah,
          downloaded: onDisk,
          total: total,
        ),
      );
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAudioDownloads.surahInfo',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<int, SurahDownloadInfo>>> allSurahsInfo(
    String reciterId,
  ) async {
    try {
      final map = <int, SurahDownloadInfo>{};
      final hasAny = await _files.reciterDirExists(reciterId);
      for (int surah = 1; surah <= AyahCounts.surahCount; surah++) {
        final total = AyahCounts.forSurah(surah);
        final onDisk = hasAny ? await _files.countDownloaded(reciterId, surah) : 0;
        map[surah] = SurahDownloadInfo(
          surahNumber: surah,
          downloaded: onDisk,
          total: total,
        );
      }
      return Right(map);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAudioDownloads.allSurahsInfo',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReciterStats>> reciterStats(String reciterId) async {
    try {
      if (!await _files.reciterDirExists(reciterId)) {
        return const Right(ReciterStats.empty());
      }
      var complete = 0;
      for (int surah = 1; surah <= AyahCounts.surahCount; surah++) {
        final total = AyahCounts.forSurah(surah);
        final onDisk = await _files.countDownloaded(reciterId, surah);
        if (total > 0 && onDisk >= total) complete++;
      }
      final bytes = await _files.bytesForReciter(reciterId);
      return Right(
        ReciterStats(
          downloadedSurahs: complete,
          totalSurahs: AyahCounts.surahCount,
          totalBytes: bytes,
        ),
      );
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAudioDownloads.reciterStats',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> deleteSurah(String reciterId, int surah) async {
    try {
      cancelSurah(reciterId, surah);
      await _files.deleteForSurah(reciterId, surah);
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReciter(String reciterId) async {
    try {
      cancelAll();
      await _files.deleteForReciter(reciterId);
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Live-state queries + cancellation
  // ---------------------------------------------------------------------------

  @override
  bool isSurahDownloading(String reciterId, int surah) =>
      _active.containsKey(_key(reciterId, surah));

  @override
  SurahDownloadProgress? activeProgress(String reciterId, int surah) =>
      _active[_key(reciterId, surah)]?.last;

  @override
  void cancelSurah(String reciterId, int surah) {
    _active[_key(reciterId, surah)]?.cancelled = true;
  }

  @override
  void cancelAll() {
    _cancelAllRequested = true;
    for (final a in _active.values) {
      a.cancelled = true;
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
