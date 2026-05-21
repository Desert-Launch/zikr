import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';
import 'package:quran/modules/quran/domain/entities/param_download_request.dart';

abstract class RDownloads {
  Future<Either<Failure, MDownloadTask>> start(ParamDownloadRequest request);
  Future<Either<Failure, void>> cancel(String taskId);
  Future<Either<Failure, void>> pause(String taskId);
  Future<Either<Failure, void>> resume(String taskId);
  Future<Either<Failure, void>> deleteTask(String taskId);
  Future<Either<Failure, void>> deleteAllForReciter(String reciterId);
  Future<Either<Failure, List<MDownloadTask>>> listTasks();
  Future<Either<Failure, int>> totalBytes();
  Stream<MDownloadTask> watchTask(String taskId);
}
