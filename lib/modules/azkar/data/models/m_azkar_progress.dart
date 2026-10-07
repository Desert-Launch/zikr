import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_azkar_progress.g.dart';

/// Tracks how many times the user has tapped through each zekr of a category
/// today, and which zekr they were on. Keyed by `<categoryId>_<yyyyMMdd>` so
/// each day starts fresh.
@HiveType(typeId: HiveTypeIds.azkarProgress)
class MAzkarProgress extends HiveObject {
  MAzkarProgress({
    required this.dayKey,
    required this.completedCounts,
    required this.updatedAt,
    this.lastItemId,
  });

  /// `"<categoryId>_<yyyyMMdd>"`. Used as the box key too.
  @HiveField(0)
  String dayKey;

  /// Per-item completed-count: item id → number of taps so far today.
  @HiveField(1)
  Map<String, int> completedCounts;

  @HiveField(2)
  DateTime updatedAt;

  /// Id of the zekr on screen when the user last left the player, so reopening
  /// the category the same day lands back on it. Null until the player opens.
  @HiveField(3)
  String? lastItemId;
}
