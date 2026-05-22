import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_tasbih_history.g.dart';

/// One completed tasbih session. Many records per day.
@HiveType(typeId: HiveTypeIds.tasbihHistory)
class MTasbihHistory extends HiveObject {
  MTasbihHistory({
    required this.id,
    required this.zekrAr,
    required this.count,
    required this.completedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String zekrAr;

  @HiveField(2)
  int count;

  @HiveField(3)
  DateTime completedAt;
}
