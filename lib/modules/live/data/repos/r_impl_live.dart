import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/live/data/datasources/remote/ds_remote_live.dart';
import 'package:quran/modules/live/domain/repos/r_live.dart';

class RImplLive implements RLive {
  RImplLive({required DSRemoteLive remote}) : _remote = remote;

  final DSRemoteLive _remote;

  @override
  Future<Either<Failure, String>> resolveLiveVideoId(String channelId) async {
    try {
      final id = await _remote.resolveLiveVideoId(channelId);
      return Right(id);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplLive.resolveLiveVideoId',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  Failure _failureFromDio(DioException e) {
    final msg = e.message ?? 'Network error';
    final code = e.response?.statusCode;
    if (code == 404) return Failure.notFoundFailure(message: msg);
    if (code != null && code >= 500) {
      return Failure.serverFailure(message: msg, statusCode: code);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure.networkFailure(message: msg);
    }
    return Failure.unexpectedFailure(message: msg);
  }
}
