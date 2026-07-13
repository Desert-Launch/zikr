import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_azkar_favorite.g.dart';

@HiveType(typeId: HiveTypeIds.azkarFavorite)
class MAzkarFavorite extends HiveObject {
  MAzkarFavorite({
    required this.itemId,
    this.categoryId,
    this.categoryNameAr,
    this.categoryNameEn,
    this.itemIndex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  String itemId;

  @HiveField(1)
  DateTime createdAt;

  /// Category the zekr belongs to — kept so favorites can reopen the counter
  /// screen at the right list without re-scanning every catalog.
  @HiveField(2)
  String? categoryId;

  @HiveField(3)
  String? categoryNameAr;

  @HiveField(4)
  String? categoryNameEn;

  /// Position of the zekr within its category, used to open the player pager.
  @HiveField(5)
  int? itemIndex;
}
