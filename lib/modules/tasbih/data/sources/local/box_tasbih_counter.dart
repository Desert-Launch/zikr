import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_counter.dart';

class BoxTasbihCounter extends HiveBoxBase<MTasbihCounter> {
  BoxTasbihCounter() : super('tasbih_counter');

  /// Record key for the general digital tasbih counter.
  static const int tasbihKey = 0;

  /// Record key for the standalone salawat counter — kept separate so it
  /// never clobbers the tasbih count.
  static const int salawatKey = 1;

  /// `yyyyMMdd` stamp that dates the record's tally — see
  /// [MTasbihCounter.countsDay].
  static String dayKey(DateTime day) {
    final yyyy = day.year.toString().padLeft(4, '0');
    final mm = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  MTasbihCounter current([int key = tasbihKey]) {
    final existing = box.get(key);
    if (existing != null) return existing;
    final fresh = key == salawatKey
        ? MTasbihCounter(target: 100)
        : MTasbihCounter();
    box.put(key, fresh);
    return fresh;
  }

  /// The record at [key] with its tally guaranteed to be today's — the
  /// per-phrase counts on the tasbih record, the single count on the salawat
  /// one. A record last counted on an earlier day — or before the counts were
  /// dated at all — comes back with the tally wiped, which is what resets both
  /// counters every morning. Settings on the record are left alone.
  MTasbihCounter today([int key = tasbihKey]) {
    final c = current(key);
    final stamp = dayKey(DateTime.now());
    if (c.countsDay != stamp) {
      c
        ..phraseCounts = <String, int>{}
        ..count = 0
        ..countsDay = stamp;
      c.save();
    }
    return c;
  }

  Future<void> save(MTasbihCounter c, [int key = tasbihKey]) async {
    await box.put(key, c);
  }
}
