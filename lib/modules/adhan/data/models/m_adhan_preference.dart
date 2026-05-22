import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_adhan_preference.g.dart';

/// User's adhan choices. Single record (key = 0) in `BoxAdhanPreference`.
@HiveType(typeId: HiveTypeIds.adhanPreference)
class MAdhanPreference extends HiveObject {
  MAdhanPreference({
    this.defaultAdhanId,
    this.fajrAdhanId,
    this.useFajrSpecific = true,
  });

  /// User-selected regular adhan. null → pick locale-default at read time.
  @HiveField(0)
  String? defaultAdhanId;

  /// User-selected Fajr adhan. null + useFajrSpecific → pick the file with
  /// is_fajr_default = true.
  @HiveField(1)
  String? fajrAdhanId;

  /// When false, regular adhan plays for Fajr too.
  @HiveField(2)
  bool useFajrSpecific;
}
