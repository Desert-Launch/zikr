import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_prayer_cache.g.dart';

/// Last computed location + raw prayer-time strings for that day. Lets the
/// app render prayer times instantly on launch even before a fresh GPS
/// fix lands.
@HiveType(typeId: HiveTypeIds.prayerCache)
class MPrayerCache extends HiveObject {
  MPrayerCache({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.fajrIso,
    required this.sunriseIso,
    required this.dhuhrIso,
    required this.asrIso,
    required this.maghribIso,
    required this.ishaIso,
    required this.computedAtIso,
  });

  @HiveField(0)
  double latitude;
  @HiveField(1)
  double longitude;
  @HiveField(2)
  String cityName;
  @HiveField(3)
  String fajrIso;
  @HiveField(4)
  String sunriseIso;
  @HiveField(5)
  String dhuhrIso;
  @HiveField(6)
  String asrIso;
  @HiveField(7)
  String maghribIso;
  @HiveField(8)
  String ishaIso;
  @HiveField(9)
  String computedAtIso;

  DateTime get computedAt => DateTime.parse(computedAtIso);
  DateTime get fajr => DateTime.parse(fajrIso);
  DateTime get sunrise => DateTime.parse(sunriseIso);
  DateTime get dhuhr => DateTime.parse(dhuhrIso);
  DateTime get asr => DateTime.parse(asrIso);
  DateTime get maghrib => DateTime.parse(maghribIso);
  DateTime get isha => DateTime.parse(ishaIso);
}
