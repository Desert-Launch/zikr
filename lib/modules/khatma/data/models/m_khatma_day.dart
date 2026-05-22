import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_khatma_day.g.dart';

/// One day's reading record for the active plan. Keyed by `yyyyMMdd`.
@HiveType(typeId: HiveTypeIds.khatmaDay)
class MKhatmaDay extends HiveObject {
  MKhatmaDay({
    required this.dateKey,
    required this.dayIndex,
    required this.targetPages,
    this.pagesRead = 0,
    this.completed = false,
    this.completedAt,
  });

  /// `yyyyMMdd` string used as the Hive box key.
  @HiveField(0)
  String dateKey;

  /// 1-indexed day in the plan (so day 1 of a 30-day plan = the first day).
  @HiveField(1)
  int dayIndex;

  @HiveField(2)
  int targetPages;

  @HiveField(3)
  int pagesRead;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  DateTime? completedAt;
}
