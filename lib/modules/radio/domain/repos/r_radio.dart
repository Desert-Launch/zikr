import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

abstract class RRadio {
  /// The curated national broadcasts (Egypt / Qatar / Saudi). Always succeeds —
  /// served from a bundled list so it works offline.
  Future<Either<Failure, List<MRadioStation>>> getNationalStations();

  /// The live station catalogue from the mp3quran.net API. Network-dependent;
  /// returns a [Failure] when offline or the host is unreachable.
  Future<Either<Failure, List<MRadioStation>>> getLiveStations({
    String language = 'ar',
  });
}
