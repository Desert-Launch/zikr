import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';

class BoxKhatmaDay extends HiveBoxBase<MKhatmaDay> {
  BoxKhatmaDay() : super('khatma_days');

  static String keyFor(DateTime day) {
    final yyyy = day.year.toString().padLeft(4, '0');
    final mm = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  List<MKhatmaDay> all() => box.values.toList()
    ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

  MKhatmaDay? today() {
    final k = keyFor(DateTime.now());
    return box.get(k);
  }

  Future<void> upsert(MKhatmaDay day) async => box.put(day.dateKey, day);

  Future<void> clearAll() async => box.clear();

  int get completedCount => box.values.where((d) => d.completed).length;
}
