import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_completion.dart';

class BoxKhatmaCompletion extends HiveBoxBase<MKhatmaCompletion> {
  BoxKhatmaCompletion() : super('khatma_completions');

  List<MKhatmaCompletion> all() => box.values.toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  Future<void> record(MKhatmaCompletion c) async => box.put(c.id, c);
}
