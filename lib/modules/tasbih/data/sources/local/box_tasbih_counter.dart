import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_counter.dart';

class BoxTasbihCounter extends HiveBoxBase<MTasbihCounter> {
  BoxTasbihCounter() : super('tasbih_counter');

  /// Record key for the general digital tasbih counter.
  static const int tasbihKey = 0;

  /// Record key for the standalone salawat counter — kept separate so it
  /// never clobbers the tasbih count.
  static const int salawatKey = 1;

  MTasbihCounter current([int key = tasbihKey]) {
    final existing = box.get(key);
    if (existing != null) return existing;
    final fresh = key == salawatKey
        ? MTasbihCounter(target: 100)
        : MTasbihCounter();
    box.put(key, fresh);
    return fresh;
  }

  Future<void> save(MTasbihCounter c, [int key = tasbihKey]) async {
    await box.put(key, c);
  }
}
