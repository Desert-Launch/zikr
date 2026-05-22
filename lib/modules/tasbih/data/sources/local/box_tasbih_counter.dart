import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_counter.dart';

class BoxTasbihCounter extends HiveBoxBase<MTasbihCounter> {
  BoxTasbihCounter() : super('tasbih_counter');

  MTasbihCounter current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MTasbihCounter();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> save(MTasbihCounter c) async {
    await box.put(0, c);
  }
}
