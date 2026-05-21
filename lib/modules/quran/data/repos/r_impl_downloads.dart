import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/data/sources/local/box_download_tasks.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/entities/param_download_request.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';

class RImplDownloads implements RDownloads {
  RImplDownloads({
    required this.tasksBox,
    required this.downloader,
    required this.remote,
    required this.files,
    required this.quran,
    required this.reciter,
  });

  final BoxDownloadTasks tasksBox;
  final DSAudioDownloader downloader;
  final DSRemoteAudio remote;
  final DSLocalAudioFiles files;
  final RQuran quran;
  final RReciter reciter;

  final Map<String, StreamController<MDownloadTask>> _watchers = {};

  void _emit(MDownloadTask task) {
    _watchers[task.id]?.add(task);
  }

  @override
  Stream<MDownloadTask> watchTask(String taskId) {
    return _watchers
        .putIfAbsent(taskId, () => StreamController<MDownloadTask>.broadcast())
        .stream;
  }

  Future<List<ParamAyahRef>> _ayatFor(ParamDownloadRequest request) async {
    final res = request.kind == DownloadKind.surah
        ? await quran.ayatOfSurah(request.number)
        : await quran.ayatOfJuz(request.number);
    return res.fold((_) => <ParamAyahRef>[], (list) => list);
  }

  @override
  Future<Either<Failure, MDownloadTask>> start(ParamDownloadRequest request) async {
    try {
      final ayat = await _ayatFor(request);
      if (ayat.isEmpty) {
        return Left(Failure.validationFailure(message: 'Nothing to download for ${request.taskId}'));
      }
      final reciters = await reciter.getReciters();
      final folder = reciters.fold<String?>(
        (_) => null,
        (list) => list.where((r) => r.id == request.reciterId).firstOrNull?.folder,
      );
      if (folder == null) {
        return Left(Failure.notFoundFailure(message: 'Reciter not found'));
      }

      var task = MDownloadTask(
        id: request.taskId,
        reciterId: request.reciterId,
        type: request.kind.name,
        number: request.number,
        totalAyat: ayat.length,
        downloadedAyat: 0,
        status: 'downloading',
        sizeBytes: 0,
      );
      await tasksBox.box.put(task.id, task);
      _emit(task);

      // Group by surah for ensureDir.
      final surahsTouched = ayat.map((a) => a.surah).toSet();
      for (final s in surahsTouched) {
        await files.ensureDir(request.reciterId, s);
      }

      // Sequential download (simpler & gentler on free CDN). Throttle writes every 5%.
      int sinceLastWrite = 0;
      int progressPct = 0;
      for (final ref in ayat) {
        if (await files.exists(request.reciterId, ref.surah, ref.ayah)) {
          task.downloadedAyat++;
        } else {
          final url = remote.primaryUrl(folder: folder, surah: ref.surah, ayah: ref.ayah);
          final path = await files.pathFor(request.reciterId, ref.surah, ref.ayah);
          try {
            await downloader.downloadFile(taskId: task.id, url: url, savePath: path);
            task.downloadedAyat++;
            task.sizeBytes += await File(path).length();
          } catch (e) {
            ErrorHelper.printDebugError(name: 'RImplDownloads.download', error: e);
            // Best-effort: continue with next ayah.
          }
        }
        sinceLastWrite++;
        final nextPct = ((task.downloadedAyat / task.totalAyat) * 100).floor();
        if (nextPct - progressPct >= 5 || sinceLastWrite >= 10) {
          progressPct = nextPct;
          sinceLastWrite = 0;
          await tasksBox.box.put(task.id, task);
          _emit(task);
        }
      }

      task.status = 'done';
      await tasksBox.box.put(task.id, task);
      _emit(task);
      return Right(task);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplDownloads.start', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancel(String taskId) async {
    try {
      downloader.cancel(taskId, 'user-cancel');
      final task = tasksBox.box.get(taskId);
      if (task != null) {
        task.status = 'paused';
        await tasksBox.box.put(taskId, task);
        _emit(task);
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pause(String taskId) => cancel(taskId);

  @override
  Future<Either<Failure, void>> resume(String taskId) async {
    final task = tasksBox.box.get(taskId);
    if (task == null) {
      return Left(Failure.notFoundFailure(message: 'Task $taskId not found'));
    }
    final request = task.type == 'juz'
        ? ParamDownloadRequest.juz(reciterId: task.reciterId, juz: task.number)
        : ParamDownloadRequest.surah(reciterId: task.reciterId, surah: task.number);
    final res = await start(request);
    return res.map((_) {});
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      final task = tasksBox.box.get(taskId);
      if (task != null) {
        if (task.type == 'surah') {
          await files.deleteForSurah(task.reciterId, task.number);
        }
        await tasksBox.box.delete(taskId);
        _emit(task..status = 'deleted');
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllForReciter(String reciterId) async {
    try {
      await files.deleteForReciter(reciterId);
      final keys = tasksBox.box.values.where((t) => t.reciterId == reciterId).map((t) => t.id).toList();
      for (final k in keys) {
        await tasksBox.box.delete(k);
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MDownloadTask>>> listTasks() async {
    try {
      return Right(tasksBox.box.values.toList(growable: false));
    } catch (e) {
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> totalBytes() async {
    try {
      return Right(await files.totalBytes());
    } catch (e) {
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
