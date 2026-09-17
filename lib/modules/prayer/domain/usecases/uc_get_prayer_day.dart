import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_day.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';

class UCGetPrayerDay {
  UCGetPrayerDay(this._repo);
  final RPrayer _repo;

  Future<Either<Failure, EDailyPrayerTimes>> call(ParamPrayerDay p) =>
      _repo.getDay(p);
}
