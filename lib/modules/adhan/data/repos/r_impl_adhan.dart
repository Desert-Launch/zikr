import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/datasources/remote/ds_remote_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_download.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_download.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';

class RImplAdhan implements RAdhan {
  RImplAdhan({
    required DSRemoteAdhan remote,
    required DSLocalAdhan local,
    required BoxAdhanDownload downloads,
  })  : _remote = remote,
        _local = local,
        _downloads = downloads;

  final DSRemoteAdhan _remote;
  final DSLocalAdhan _local;
  final BoxAdhanDownload _downloads;

  @override
  Future<Either<Failure, List<MAdhan>>> fetchCatalog() async {
    // Bundled list is the baseline and must always succeed.
    List<MAdhan> bundled;
    try {
      bundled = await _local.all();
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAdhan.fetchCatalog(bundled)',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }

    // Remote catalog is opt-in. When no CDN URL is configured, skip the
    // network entirely and serve the bundled list.
    if (EndPoints.adhanCatalog.isEmpty) return Right(bundled);

    // Remote is best-effort — merge its extra/updated voices over the bundled
    // ones; on any failure just return bundled.
    try {
      final remote = await _remote.fetchCatalog();
      final byId = {for (final v in bundled) v.id: v};
      for (final v in remote) {
        byId[v.id] = v;
      }
      return Right(byId.values.toList(growable: false));
    } catch (e) {
      // Offline / no CDN yet → bundled-only is the correct, expected result.
      return Right(bundled);
    }
  }

  @override
  Future<Either<Failure, String>> downloadVoice(
    String voiceId, {
    void Function(int received, int total)? onProgress,
  }) async {
    File? target;
    try {
      final catalog = await fetchCatalog();
      final list = catalog.getOrElse(() => const <MAdhan>[]);
      MAdhan? voice;
      for (final v in list) {
        if (v.id == voiceId) {
          voice = v;
          break;
        }
      }
      final url = voice?.fullUrl;
      if (voice == null || url == null || url.isEmpty) {
        return Left(
          Failure.validationFailure(message: 'Voice has no download URL'),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final adhansDir = Directory(p.join(dir.path, 'adhans'));
      if (!await adhansDir.exists()) {
        await adhansDir.create(recursive: true);
      }
      final savePath = p.join(adhansDir.path, '${voiceId}_full.mp3');
      target = File(savePath);

      await _remote.downloadFile(url, savePath, onProgress: onProgress);

      await _downloads.save(MAdhanDownload(
        voiceId: voiceId,
        fullUrl: url,
        localPath: savePath,
        downloaded: true,
        sizeBytes: await target.length(),
      ));
      return Right(savePath);
    } on DioException catch (e) {
      await _safeDelete(target);
      return Left(_failureFromDio(e));
    } catch (e, st) {
      await _safeDelete(target);
      ErrorHelper.printDebugError(
        name: 'RImplAdhan.downloadVoice',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDownloadedVoice(String voiceId) async {
    try {
      final rec = _downloads.byId(voiceId);
      final path = rec?.localPath;
      if (path != null) await _safeDelete(File(path));
      await _downloads.remove(voiceId);
      return const Right(unit);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplAdhan.deleteDownloadedVoice',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  Future<void> _safeDelete(File? f) async {
    try {
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  Failure _failureFromDio(DioException e) {
    final msg = e.message ?? 'Download failed';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure.networkFailure(message: msg);
    }
    final code = e.response?.statusCode;
    if (code == 404) return Failure.notFoundFailure(message: msg);
    return Failure.serverFailure(message: msg, statusCode: code);
  }
}
