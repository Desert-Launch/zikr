import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/domain/repos/r_radio.dart';

class UCGetLiveStations {
  UCGetLiveStations(this._repo);
  final RRadio _repo;

  Future<Either<Failure, List<MRadioStation>>> call({String language = 'ar'}) =>
      _repo.getLiveStations(language: language);
}
