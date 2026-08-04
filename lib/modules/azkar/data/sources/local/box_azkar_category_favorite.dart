import 'package:quran/core/utils/hive_box_base.dart';

/// Favorited categories from the "other azkar" browser, keyed by category id
/// with the Arabic name stored as the value. Plain [String] storage — no Hive
/// adapter needed, unlike the per-zekr [BoxAzkarFavorite].
class BoxAzkarCategoryFavorite extends HiveBoxBase<String> {
  BoxAzkarCategoryFavorite() : super('azkar_category_favorites');

  /// Ids of every favorited category, for a cheap membership test while
  /// building the list.
  Set<String> ids() => box.keys.map((k) => k.toString()).toSet();

  bool isFavorite(String categoryId) => box.containsKey(categoryId);

  Future<void> toggle(String categoryId, {required String nameAr}) async {
    if (isFavorite(categoryId)) {
      await box.delete(categoryId);
    } else {
      await box.put(categoryId, nameAr);
    }
  }
}
