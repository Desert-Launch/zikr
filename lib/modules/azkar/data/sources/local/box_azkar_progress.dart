import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_progress.dart';

class BoxAzkarProgress extends HiveBoxBase<MAzkarProgress> {
  BoxAzkarProgress() : super('azkar_progress');

  static String keyFor(String categoryId, DateTime day) {
    final yyyy = day.year.toString().padLeft(4, '0');
    final mm = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '${categoryId}_$yyyy$mm$dd';
  }

  MAzkarProgress today(String categoryId) {
    final k = keyFor(categoryId, DateTime.now());
    final existing = box.get(k);
    if (existing != null) return existing;
    final fresh = MAzkarProgress(
      dayKey: k,
      completedCounts: <String, int>{},
      updatedAt: DateTime.now(),
    );
    box.put(k, fresh);
    return fresh;
  }

  Future<void> increment(String categoryId, String itemId) async {
    final r = today(categoryId);
    r.completedCounts[itemId] = (r.completedCounts[itemId] ?? 0) + 1;
    r.updatedAt = DateTime.now();
    await r.save();
  }

  /// Remembers [itemId] as the zekr on screen in today's session of
  /// [categoryId]. Tomorrow's record starts without one.
  Future<void> setLastItem(String categoryId, String itemId) async {
    final r = today(categoryId);
    if (r.lastItemId == itemId) return;
    r.lastItemId = itemId;
    r.updatedAt = DateTime.now();
    await r.save();
  }

  /// Index of the zekr today's session of [category] was left on, or null when
  /// there's nothing to pick up: no session today, one that never got past
  /// the first zekr untouched, or every zekr already done.
  int? resumeIndex(MAzkarCategory category) {
    // `box.get`, not `today()` — only checking, so don't create a record.
    final r = box.get(keyFor(category.id, DateTime.now()));
    final lastItemId = r?.lastItemId;
    if (r == null || lastItemId == null) return null;
    final index = category.items.indexWhere((item) => item.id == lastItemId);
    if (index < 0) return null;
    if (index == 0 && r.completedCounts.isEmpty) return null;
    final finished = category.items.every((item) => (r.completedCounts[item.id] ?? 0) >= item.repeat);
    return finished ? null : index;
  }

  Future<void> reset(String categoryId) async {
    final k = keyFor(categoryId, DateTime.now());
    await box.delete(k);
  }

  Future<void> resetItem(String categoryId, String itemId) async {
    final r = today(categoryId);
    r.completedCounts.remove(itemId);
    r.updatedAt = DateTime.now();
    await r.save();
  }
}
