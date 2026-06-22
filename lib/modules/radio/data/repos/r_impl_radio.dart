import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/radio/data/datasources/local/ds_local_radio.dart';
import 'package:quran/modules/radio/data/datasources/remote/ds_remote_radio.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/domain/repos/r_radio.dart';

class RImplRadio implements RRadio {
  RImplRadio({required DSLocalRadio local, required DSRemoteRadio remote})
      : _local = local,
        _remote = remote;

  final DSLocalRadio _local;
  final DSRemoteRadio _remote;

  @override
  Future<Either<Failure, List<MRadioStation>>> getNationalStations() async {
    try {
      return Right(_local.nationalStations());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplRadio.getNationalStations',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MRadioStation>>> getLiveStations({
    String language = 'ar',
  }) async {
    try {
      final list = await _remote.fetchStations(language: language);
      return Right(list);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplRadio.getLiveStations',
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
