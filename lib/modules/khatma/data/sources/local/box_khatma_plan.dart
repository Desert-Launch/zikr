import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';

class BoxKhatmaPlan extends HiveBoxBase<MKhatmaPlan> {
  BoxKhatmaPlan() : super('khatma_plan');

  MKhatmaPlan? current() => box.get(0);

  Future<void> save(MKhatmaPlan plan) async => box.put(0, plan);

  Future<void> clear() async => box.delete(0);
}
