import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';

class UCGetPrayerCalendar {
  UCGetPrayerCalendar(this._repo);
  final RPrayer _repo;

  Future<Either<Failure, EPrayerCalendar>> call(ParamPrayerCalendar p) =>
      _repo.getCalendar(p);
}
