import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_favorite.dart';

class BoxAzkarFavorite extends HiveBoxBase<MAzkarFavorite> {
  BoxAzkarFavorite() : super('azkar_favorites');

  Iterable<MAzkarFavorite> all() => box.values;

  bool isFavorite(String itemId) => box.containsKey(itemId);

  Future<void> toggle(
    String itemId, {
    String? categoryId,
    String? categoryNameAr,
    String? categoryNameEn,
    int? itemIndex,
  }) async {
    if (isFavorite(itemId)) {
      await box.delete(itemId);
    } else {
      await box.put(
        itemId,
        MAzkarFavorite(
          itemId: itemId,
          categoryId: categoryId,
          categoryNameAr: categoryNameAr,
          categoryNameEn: categoryNameEn,
          itemIndex: itemIndex,
        ),
      );
    }
  }
}
