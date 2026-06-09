import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';

class UCGetPrayerTimes {
  UCGetPrayerTimes(this._repo);
  final RPrayer _repo;

  Future<Either<Failure, MPrayerTimings>> call(ParamPrayerTimes p) =>
      _repo.getTimings(p);
}
