import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_azkar_audio_files.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar_audio.dart';
import 'package:quran/modules/azkar/data/datasources/remote/ds_azkar_audio_downloader.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_download.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_audio_download.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_audio_pref.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/services/azkar_audio_resolver.dart';

/// One in-flight pack download, shared by every caller that asks for it.
class _ActivePack {
  _ActivePack(this.controller);
  final StreamController<AzkarPackProgress> controller;
  bool cancelled = false;
  AzkarPackProgress? last;
}

class RImplAzkarAudio implements RAzkarAudio {
  RImplAzkarAudio({
    required DSLocalAzkarAudio manifest,
    required DSAzkarAudioFiles files,
    required DSAzkarAudioDownloader downloader,
    required BoxAzkarAudioDownload downloads,
    required BoxAzkarAudioPref prefs,
    required DSLocalAzkar azkar,
    Connectivity? connectivity,
    AzkarAudioResolver resolver = const AzkarAudioResolver(),
  }) : _manifest = manifest,
       _files = files,
       _downloader = downloader,
       _downloads = downloads,
       _prefs = prefs,
       _azkar = azkar,
       _connectivity = connectivity ?? Connectivity(),
       _resolver = resolver;

  final DSLocalAzkarAudio _manifest;
  final DSAzkarAudioFiles _files;
  final DSAzkarAudioDownloader _downloader;
  final BoxAzkarAudioDownload _downloads;
  final BoxAzkarAudioPref _prefs;
  final DSLocalAzkar _azkar;
  final Connectivity _connectivity;
  final AzkarAudioResolver _resolver;

  /// Files fetched at once. Enough to keep a pack moving, few enough to stay
  /// polite to a free host — the sources here are donated bandwidth.
  static const int concurrency = 4;

  final Map<String, _ActivePack> _active = <String, _ActivePack>{};

  /// Local paths of completed downloads, mirrored in memory so the resolver
  /// (called on every dhikr the user swipes to) does not hit Hive each time.
  final Map<String, String> _localPaths = <String, String>{};
  bool _localPathsPrimed = false;

  static const String _tag = 'RImplAzkarAudio';

  // ---------------------------------------------------------------------------
  // Catalogue
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<MAzkarReader>>> readers() async {
    try {
      return Right(await _manifest.readers());
    } catch (e, st) {
      return Left(_unexpected('readers', e, st));
    }
  }

  @override
  Future<Either<Failure, List<MAzkarReader>>> readersForAdhkar(
    String adhkarId,
  ) async {
    try {
      final all = await _manifest.readers();
      final hits = <MAzkarReader>[];
      for (final reader in all) {
        final index = await _manifest.indexFor(reader.id);
        if (index.forAdhkar(adhkarId) != null) hits.add(reader);
      }
      return Right(hits);
    } catch (e, st) {
      return Left(_unexpected('readersForAdhkar', e, st));
    }
  }

  @override
  Future<Either<Failure, List<MAzkarReader>>> readersForCategory(
    String categoryId,
  ) async {
    try {
      final all = await _manifest.readers();
      final hits = <MAzkarReader>[];
      for (final reader in all) {
        final index = await _manifest.indexFor(reader.id);
        if (index.forCategory(categoryId).isNotEmpty) hits.add(reader);
      }
      return Right(hits);
    } catch (e, st) {
      return Left(_unexpected('readersForCategory', e, st));
    }
  }

  // ---------------------------------------------------------------------------
  // Playback resolution
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, EAzkarAudioSource>> resolveAdhkar(
    String adhkarId, {
    String? forceReaderId,
  }) => _resolve(
    forceReaderId: forceReaderId,
    pick: (index) => index.forAdhkar(adhkarId),
    label: 'resolveAdhkar',
  );

  @override
  Future<Either<Failure, EAzkarAudioSource>> resolveCategory(
    String categoryId, {
    String? forceReaderId,
  }) => _resolve(
    forceReaderId: forceReaderId,
    pick: (index) {
      final hits = index.forCategory(categoryId);
      return hits.isEmpty ? null : hits.first;
    },
    label: 'resolveCategory',
  );

  Future<Either<Failure, EAzkarAudioSource>> _resolve({
    required String? forceReaderId,
    required MAzkarAudio? Function(MAzkarReaderAudioIndex index) pick,
    required String label,
  }) async {
    try {
      final all = await _manifest.readers();
      if (all.isEmpty) return const Right(EAzkarAudioSource.none());

      // Only the readers actually consulted get their mapping parsed, but the
      // resolver needs a synchronous lookup, so pre-resolve the candidates in
      // manifest order first.
      final candidates = <String, MAzkarAudio?>{};
      for (final reader in all) {
        candidates[reader.id] = pick(await _manifest.indexFor(reader.id));
      }

      await _primeLocalPaths();
      final online = await _isOnline();

      return Right(
        _resolver.resolve(
          preferredReaderId: forceReaderId ?? _prefs.preferredReaderId,
          readers: all,
          lookup: (readerId) => candidates[readerId],
          isDownloaded: (audio) => _localPaths.containsKey(audio.id),
          localPathOf: (audio) => _localPaths[audio.id] ?? '',
          isOnline: online,
        ),
      );
    } catch (e, st) {
      return Left(_unexpected(label, e, st));
    }
  }

  Future<void> _primeLocalPaths() async {
    if (_localPathsPrimed) return;
    for (final record in _downloads.all()) {
      final path = record.localPath;
      if (record.isDownloaded && path != null && path.isNotEmpty) {
        _localPaths[record.audioId] = path;
      }
    }
    _localPathsPrimed = true;
  }

  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      // Treat an unreadable radio state as online: streaming then fails loudly
      // instead of the app wrongly claiming there is no audio.
      AppLogger.warning('Connectivity check failed: $e', tag: _tag);
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, AzkarReaderStats>> readerStats(String readerId) async {
    try {
      return Right(await _statsFor(readerId));
    } catch (e, st) {
      return Left(_unexpected('readerStats', e, st));
    }
  }

  Future<AzkarReaderStats> _statsFor(String readerId) async {
    final entries = await _manifest.allFor(readerId);
    final records = _downloads.forReader(readerId);
    final downloaded = records.where((r) => r.isDownloaded).length;
    final failed = records.where((r) => r.isFailed).length;
    final bytesOnDisk = await _files.readerDirExists(readerId)
        ? await _files.bytesForReader(readerId)
        : 0;
    final estimated = entries.fold<int>(
      0,
      (sum, e) => sum + (e.fileSize ?? 0),
    );
    return AzkarReaderStats(
      readerId: readerId,
      downloaded: downloaded,
      total: entries.length,
      failed: failed,
      bytesOnDisk: bytesOnDisk,
      estimatedBytes: estimated,
    );
  }

  @override
  Future<Either<Failure, Map<String, AzkarReaderStats>>>
  allReaderStats() async {
    try {
      final map = <String, AzkarReaderStats>{};
      for (final reader in await _manifest.readers()) {
        map[reader.id] = await _statsFor(reader.id);
      }
      return Right(map);
    } catch (e, st) {
      return Left(_unexpected('allReaderStats', e, st));
    }
  }

  @override
  Future<Either<Failure, List<AzkarCategoryAudioInfo>>> categoryBreakdown(
    String readerId,
  ) async {
    try {
      final entries = await _manifest.allFor(readerId);
      final downloadedIds = _downloads.downloadedIdsFor(readerId);
      final names = await _categoryNames();

      final grouped = <String, List<MAzkarAudio>>{};
      for (final entry in entries) {
        for (final categoryId in entry.categoryIds) {
          grouped.putIfAbsent(categoryId, () => <MAzkarAudio>[]).add(entry);
        }
      }

      final out = <AzkarCategoryAudioInfo>[];
      for (final e in grouped.entries) {
        final name = names[e.key];
        out.add(
          AzkarCategoryAudioInfo(
            categoryId: e.key,
            nameAr: name?.ar ?? e.key,
            nameEn: name?.en ?? e.key,
            downloaded: e.value
                .where((a) => downloadedIds.contains(a.id))
                .length,
            total: e.value.length,
            bytes: e.value.fold<int>(0, (sum, a) => sum + (a.fileSize ?? 0)),
            hasCategoryRecording: e.value.any((a) => a.isCategoryRecording),
          ),
        );
      }
      // Biggest slices first — morning/evening ahead of a one-dua chapter.
      out.sort((a, b) => b.total.compareTo(a.total));
      return Right(out);
    } catch (e, st) {
      return Left(_unexpected('categoryBreakdown', e, st));
    }
  }

  Map<String, ({String ar, String en})>? _categoryNameCache;

  Future<Map<String, ({String ar, String en})>> _categoryNames() async {
    final cached = _categoryNameCache;
    if (cached != null) return cached;
    final map = <String, ({String ar, String en})>{};
    for (final category in [
      ...await _azkar.allCategories(),
      ...await _azkar.otherCategories(),
    ]) {
      map[category.id] = (ar: category.nameAr, en: category.nameEn);
    }
    _categoryNameCache = map;
    return map;
  }

  // ---------------------------------------------------------------------------
  // Downloads
  // ---------------------------------------------------------------------------

  String _packKey(String readerId, String? categoryId) =>
      categoryId == null ? readerId : '$readerId::$categoryId';

  @override
  Stream<AzkarPackProgress> download(String readerId, {String? categoryId}) {
    // A whole-reader run subsumes a per-category one, so join it rather than
    // starting a second writer over the same files.
    final existing =
        _active[_packKey(readerId, categoryId)] ?? _active[readerId];
    if (existing != null) return existing.controller.stream;

    final controller = StreamController<AzkarPackProgress>.broadcast();
    final pack = _ActivePack(controller);
    _active[_packKey(readerId, categoryId)] = pack;
    // Run eagerly: the transfer must proceed whether or not the screen that
    // started it is still listening.
    scheduleMicrotask(() => _runPack(readerId, categoryId, pack));
    return controller.stream;
  }

  Future<void> _runPack(
    String readerId,
    String? categoryId,
    _ActivePack pack,
  ) async {
    final key = _packKey(readerId, categoryId);
    var progress = AzkarPackProgress(
      readerId: readerId,
      categoryId: categoryId,
      completed: 0,
      total: 0,
    );
    try {
      final all = await _manifest.allFor(readerId);
      final wanted = categoryId == null
          ? all
          : all
                .where((a) => a.categoryIds.contains(categoryId))
                .toList(growable: false);
      if (wanted.isEmpty) {
        _emit(pack, progress);
        return;
      }

      await _files.ensureReaderDir(readerId);

      // Skip what is already complete on disk — this is what makes a resumed
      // pack cheap and a re-tap idempotent.
      final pending = <MAzkarAudio>[];
      var alreadyDone = 0;
      for (final audio in wanted) {
        if (await _files.exists(audio)) {
          alreadyDone++;
          await _markDownloaded(audio);
        } else {
          pending.add(audio);
        }
      }

      progress = progress.copyWith(
        total: wanted.length,
        completed: alreadyDone,
      );
      _emit(pack, progress);
      if (pending.isEmpty) return;

      var completed = alreadyDone;
      var failed = 0;

      for (var i = 0; i < pending.length; i += concurrency) {
        if (pack.cancelled) break;
        final chunk = pending.skip(i).take(concurrency).toList(growable: false);
        final results = await Future.wait(
          chunk.map(
            (audio) => _downloadOne(
              audio,
              onBytes: (received, total) {
                if (pack.cancelled) return;
                _emit(
                  pack,
                  progress.copyWith(
                    completed: completed,
                    failed: failed,
                    currentBytes: received,
                    currentTotalBytes: total,
                  ),
                );
              },
            ),
          ),
        );
        for (final ok in results) {
          if (ok) {
            completed++;
          } else if (!pack.cancelled) {
            failed++;
          }
        }
        progress = progress.copyWith(
          completed: completed,
          failed: failed,
          currentBytes: 0,
          currentTotalBytes: 0,
        );
        _emit(pack, progress);
      }

      if (pack.cancelled) {
        _emit(pack, progress.copyWith(cancelled: true));
      }
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: '$_tag._runPack',
        error: e,
        stackTrace: st,
      );
      _emit(pack, progress.copyWith(error: e.toString()));
    } finally {
      _active.remove(key);
      if (!pack.controller.isClosed) await pack.controller.close();
    }
  }

  void _emit(_ActivePack pack, AzkarPackProgress progress) {
    pack.last = progress;
    if (!pack.controller.isClosed) pack.controller.add(progress);
  }

  Future<bool> _downloadOne(
    MAzkarAudio audio, {
    void Function(int received, int total)? onBytes,
  }) async {
    final savePath = await _files.pathFor(audio);
    final partPath = await _files.partPathFor(audio);
    final existing = await _files.partialBytes(audio);

    await _downloads.save(
      MAzkarAudioDownload(
        audioId: audio.id,
        readerId: audio.readerId,
        remoteUrl: audio.remoteUrl,
        adhkarId: audio.adhkarId,
        categoryIds: List<String>.from(audio.categoryIds),
        localPath: savePath,
        bytesDownloaded: existing,
        totalBytes: audio.fileSize ?? 0,
        status: MAzkarAudioDownload.statusDownloading,
      ),
    );

    try {
      final result = await _downloader.download(
        taskId: audio.id,
        url: audio.remoteUrl,
        savePath: savePath,
        partPath: partPath,
        existingBytes: existing,
        onProgress: onBytes,
      );
      if (result.cancelled) {
        await _downloads.save(
          MAzkarAudioDownload(
            audioId: audio.id,
            readerId: audio.readerId,
            remoteUrl: audio.remoteUrl,
            adhkarId: audio.adhkarId,
            categoryIds: List<String>.from(audio.categoryIds),
            localPath: savePath,
            bytesDownloaded: await _files.partialBytes(audio),
            totalBytes: audio.fileSize ?? 0,
            status: MAzkarAudioDownload.statusPending,
          ),
        );
        return false;
      }
      await _markDownloaded(audio, bytes: result.bytes);
      return true;
    } catch (e) {
      final message = e is DioException ? (e.message ?? 'Network error') : '$e';
      AppLogger.warning(
        'Adhkar audio download failed (${audio.id}): $message',
        tag: _tag,
      );
      await _downloads.save(
        MAzkarAudioDownload(
          audioId: audio.id,
          readerId: audio.readerId,
          remoteUrl: audio.remoteUrl,
          adhkarId: audio.adhkarId,
          categoryIds: List<String>.from(audio.categoryIds),
          localPath: savePath,
          bytesDownloaded: await _files.partialBytes(audio),
          totalBytes: audio.fileSize ?? 0,
          status: MAzkarAudioDownload.statusFailed,
          error: message,
        ),
      );
      return false;
    }
  }

  Future<void> _markDownloaded(MAzkarAudio audio, {int? bytes}) async {
    final path = await _files.pathFor(audio);
    final size = bytes ?? await _files.sizeOf(audio);
    await _downloads.save(
      MAzkarAudioDownload(
        audioId: audio.id,
        readerId: audio.readerId,
        remoteUrl: audio.remoteUrl,
        adhkarId: audio.adhkarId,
        categoryIds: List<String>.from(audio.categoryIds),
        localPath: path,
        bytesDownloaded: size,
        totalBytes: audio.fileSize ?? size,
        status: MAzkarAudioDownload.statusDownloaded,
      ),
    );
    _localPaths[audio.id] = path;
  }

  @override
  bool isDownloading(String readerId) =>
      _active.keys.any((k) => k == readerId || k.startsWith('$readerId::'));

  @override
  AzkarPackProgress? activeProgress(String readerId) {
    for (final entry in _active.entries) {
      if (entry.key == readerId || entry.key.startsWith('$readerId::')) {
        return entry.value.last;
      }
    }
    return null;
  }

  @override
  void cancel(String readerId) {
    for (final entry in _active.entries) {
      if (entry.key == readerId || entry.key.startsWith('$readerId::')) {
        entry.value.cancelled = true;
      }
    }
    // Cancel the in-flight HTTP tasks too, otherwise the current chunk keeps
    // running until it finishes on its own.
    _downloader.cancelAll('pack cancelled');
  }

  @override
  void cancelAll() {
    for (final pack in _active.values) {
      pack.cancelled = true;
    }
    _downloader.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Deletion + storage
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> deleteReader(String readerId) async {
    try {
      cancel(readerId);
      final ids = _downloads
          .forReader(readerId)
          .map((r) => r.audioId)
          .toList(growable: false);
      await _files.deleteReader(readerId);
      await _downloads.removeReader(readerId);
      _localPaths.removeWhere((id, _) => ids.contains(id));
      return const Right(null);
    } catch (e, st) {
      return Left(_unexpected('deleteReader', e, st));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(
    String readerId,
    String categoryId,
  ) async {
    try {
      final entries = await _manifest.allFor(readerId);
      for (final audio in entries) {
        if (!audio.categoryIds.contains(categoryId)) continue;
        // A file shared with another category the user keeps must stay: the
        // combined "morning and evening" recording is one file in two lists.
        final sharedElsewhere = audio.categoryIds.length > 1;
        if (sharedElsewhere) continue;
        await _files.delete(audio);
        await _downloads.remove(audio.id);
        _localPaths.remove(audio.id);
      }
      return const Right(null);
    } catch (e, st) {
      return Left(_unexpected('deleteCategory', e, st));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAll() async {
    try {
      cancelAll();
      await _files.deleteAll();
      await _downloads.clear();
      _localPaths.clear();
      return const Right(null);
    } catch (e, st) {
      return Left(_unexpected('deleteAll', e, st));
    }
  }

  @override
  Future<Either<Failure, AzkarStorageUsage>> storageUsage() async {
    try {
      final perReader = <String, int>{};
      for (final reader in await _manifest.readers()) {
        final bytes = await _files.readerDirExists(reader.id)
            ? await _files.bytesForReader(reader.id)
            : 0;
        if (bytes > 0) perReader[reader.id] = bytes;
      }
      return Right(
        AzkarStorageUsage(
          totalBytes: await _files.totalBytes(),
          perReader: perReader,
        ),
      );
    } catch (e, st) {
      return Left(_unexpected('storageUsage', e, st));
    }
  }

  // ---------------------------------------------------------------------------
  // Reconciliation
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, int>> reconcile() async {
    try {
      var repaired = 0;
      for (final record in _downloads.all()) {
        final path = record.localPath ?? '';
        final onDisk = path.isNotEmpty && await File(path).exists();

        if (record.isDownloaded && !onDisk) {
          // The OS reclaimed the file, or the user cleared app storage. The
          // table said "downloaded"; disk says otherwise, and disk wins.
          await _downloads.remove(record.audioId);
          _localPaths.remove(record.audioId);
          repaired++;
          continue;
        }
        if (!record.isDownloaded && onDisk) {
          // A transfer finished but the process died before the record was
          // updated. The bytes are there and complete (the rename is the last
          // step), so promote it instead of fetching it again.
          record
            ..status = MAzkarAudioDownload.statusDownloaded
            ..bytesDownloaded = await File(path).length()
            ..error = null;
          await _downloads.save(record);
          _localPaths[record.audioId] = path;
          repaired++;
          continue;
        }
        if (record.status == MAzkarAudioDownload.statusDownloading) {
          // Nothing is in flight at startup, so a "downloading" row is a
          // leftover from a kill. Demote it to pending: the part file is still
          // there and the next run resumes from it.
          record.status = MAzkarAudioDownload.statusPending;
          await _downloads.save(record);
          repaired++;
        }
      }
      _localPathsPrimed = false;
      await _primeLocalPaths();
      if (repaired > 0) {
        AppLogger.info(
          'Adhkar audio: repaired $repaired download records',
          tag: _tag,
        );
      }
      return Right(repaired);
    } catch (e, st) {
      return Left(_unexpected('reconcile', e, st));
    }
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  @override
  String? get preferredReaderId => _prefs.preferredReaderId;

  @override
  Future<Either<Failure, void>> setPreferredReader(String? readerId) async {
    try {
      await _prefs.setPreferredReaderId(readerId);
      return const Right(null);
    } catch (e, st) {
      return Left(_unexpected('setPreferredReader', e, st));
    }
  }

  Failure _unexpected(String name, Object error, StackTrace stackTrace) {
    ErrorHelper.printDebugError(
      name: '$_tag.$name',
      error: error,
      stackTrace: stackTrace,
    );
    if (error is DioException) {
      return Failure.networkFailure(message: error.message ?? 'Network error');
    }
    return Failure.unexpectedFailure(message: error.toString());
  }
}
