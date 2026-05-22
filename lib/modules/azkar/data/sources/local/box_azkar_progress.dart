import 'package:quran/core/utils/hive_box_base.dart';
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

  Future<void> reset(String categoryId) async {
    final k = keyFor(categoryId, DateTime.now());
    await box.delete(k);
  }
}
