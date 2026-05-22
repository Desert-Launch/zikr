import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_khatma_plan.g.dart';

/// User's active khatma plan. Single record (key = 0). When the user finishes
/// a khatma, this becomes idle until they tap "start a new khatma".
@HiveType(typeId: HiveTypeIds.khatmaPlan)
class MKhatmaPlan extends HiveObject {
  MKhatmaPlan({
    required this.totalDays,
    required this.startedAt,
    this.isActive = true,
  });

  /// 30, 60, or any custom positive number — total length of the plan.
  @HiveField(0)
  int totalDays;

  @HiveField(1)
  DateTime startedAt;

  @HiveField(2)
  bool isActive;

  /// Daily reading target (in pages) — `604 / totalDays` rounded up.
  int get pagesPerDay => (604 / totalDays).ceil();
}
