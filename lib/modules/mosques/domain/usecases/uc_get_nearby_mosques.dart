import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/domain/repos/r_mosques.dart';

class UCGetNearbyMosques {
  UCGetNearbyMosques(this._repo);
  final RMosques _repo;

  Future<Either<Failure, List<EMosque>>> call({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) =>
      _repo.getNearby(
        latitude: latitude,
        longitude: longitude,
        languageCode: languageCode,
      );
}
