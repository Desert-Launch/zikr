import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';

abstract class RMosques {
  /// The mosques closest to ([latitude], [longitude]), nearest first. Names and
  /// addresses come back in [languageCode] where Google has them. An empty list
  /// means none were found in range, not an error.
  Future<Either<Failure, List<EMosque>>> getNearby({
    required double latitude,
    required double longitude,
    required String languageCode,
  });
}
