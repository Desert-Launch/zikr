import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_khatma_completion.g.dart';

/// Historical record of a finished khatma. Preserved forever so users can
/// see how many khatmas they've completed over time.
@HiveType(typeId: HiveTypeIds.khatmaCompletion)
class MKhatmaCompletion extends HiveObject {
  MKhatmaCompletion({
    required this.id,
    required this.planTotalDays,
    required this.startedAt,
    required this.completedAt,
    required this.daysCompleted,
    required this.longestStreakDays,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  int planTotalDays;

  @HiveField(2)
  DateTime startedAt;

  @HiveField(3)
  DateTime completedAt;

  @HiveField(4)
  int daysCompleted;

  @HiveField(5)
  int longestStreakDays;
}
