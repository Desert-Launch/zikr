import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_azkar_favorite.g.dart';

@HiveType(typeId: HiveTypeIds.azkarFavorite)
class MAzkarFavorite extends HiveObject {
  MAzkarFavorite({required this.itemId, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  String itemId;

  @HiveField(1)
  DateTime createdAt;
}
