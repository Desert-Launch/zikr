import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_prayer_settings.g.dart';

/// User-tunable prayer-calculation preferences. Single record (key = 0) in
/// `BoxPrayerSettings`.
@HiveType(typeId: HiveTypeIds.prayerSettings)
class MPrayerSettings extends HiveObject {
  MPrayerSettings({
    this.calculationMethodIndex = 1, // egyptian by default
    this.madhabIndex = 0,            // shafi by default
    this.notifyForPrayer = const [true, true, true, true, true],
    this.adhanIdPerPrayer,
    this.fajrAdhanId,
  });

  /// Index into the `adhan` package's CalculationMethod enum.
  @HiveField(0)
  int calculationMethodIndex;

  /// 0 = shafi, 1 = hanafi.
  @HiveField(1)
  int madhabIndex;

  /// One bool per prayer in fajr/dhuhr/asr/maghrib/isha order.
  @HiveField(2)
  List<bool> notifyForPrayer;

  /// Override adhan per prayer (null → use default).
  /// Keys: 'fajr','dhuhr','asr','maghrib','isha'.
  @HiveField(3)
  Map<String, String>? adhanIdPerPrayer;

  /// Optional Fajr-specific adhan override.
  @HiveField(4)
  String? fajrAdhanId;
}
