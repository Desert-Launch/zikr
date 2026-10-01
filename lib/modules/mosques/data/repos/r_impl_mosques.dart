import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/mosques/data/datasources/remote/ds_remote_mosques.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/domain/repos/r_mosques.dart';

class RImplMosques implements RMosques {
  RImplMosques({required DSRemoteMosques remote}) : _remote = remote;

  final DSRemoteMosques _remote;

  @override
  Future<Either<Failure, List<EMosque>>> getNearby({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    try {
      final places = await _remote.searchNearby(
        latitude: latitude,
        longitude: longitude,
        languageCode: languageCode,
      );
      // Measured on-device from the reader's own fix, so the figure on each
      // card is the distance from where they stand, not from Google's centre.
      final mosques = places
          .map((m) => m.toEntity(
                distanceMeters: Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  m.latitude,
                  m.longitude,
                ),
              ))
          .toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return Right(mosques);
    } on DioException catch (e) {
      // Google's error body names the cause (key not valid, API not enabled,
      // quota) — the one thing worth having when the list comes back empty.
      AppLogger.warning(
        'Places nearby search failed: ${e.response?.statusCode} ${e.response?.data}',
        tag: 'RImplMosques',
      );
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplMosques.getNearby',
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
