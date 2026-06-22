import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/domain/repos/r_radio.dart';

class UCGetNationalStations {
  UCGetNationalStations(this._repo);
  final RRadio _repo;

  Future<Either<Failure, List<MRadioStation>>> call() =>
      _repo.getNationalStations();
}
