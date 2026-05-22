import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';

class BoxTasbihHistory extends HiveBoxBase<MTasbihHistory> {
  BoxTasbihHistory() : super('tasbih_history');

  Iterable<MTasbihHistory> all() => box.values;

  Future<void> log(MTasbihHistory h) async => box.put(h.id, h);

  Future<void> clearAll() async => box.clear();

  int totalToday() {
    final today = DateTime.now();
    int sum = 0;
    for (final h in box.values) {
      if (h.completedAt.year == today.year &&
          h.completedAt.month == today.month &&
          h.completedAt.day == today.day) {
        sum += h.count;
      }
    }
    return sum;
  }
}
