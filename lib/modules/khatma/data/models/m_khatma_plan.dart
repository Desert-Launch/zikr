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
    this.planId = 0,
    this.currentWirdIndex = 1,
    this.reminderEnabled = true,
    this.reminderHour = 8,
    this.reminderMinute = 0,
  });

  /// 30, 60, or any custom positive number — total length of the plan.
  @HiveField(0)
  int totalDays;

  @HiveField(1)
  DateTime startedAt;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  int planId;

  /// One-indexed next wird to complete.
  @HiveField(4)
  int currentWirdIndex;

  @HiveField(5)
  bool reminderEnabled;

  @HiveField(6)
  int reminderHour;

  @HiveField(7)
  int reminderMinute;
}
