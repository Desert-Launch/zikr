import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_preference.dart';

class BoxAdhanPreference extends HiveBoxBase<MAdhanPreference> {
  BoxAdhanPreference() : super('adhan_preference');

  MAdhanPreference current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MAdhanPreference();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> setDefault(String adhanId) async {
    final r = current();
    r.defaultAdhanId = adhanId;
    await r.save();
  }

  Future<void> setFajr(String? adhanId, {required bool useFajrSpecific}) async {
    final r = current();
    r.fajrAdhanId = adhanId;
    r.useFajrSpecific = useFajrSpecific;
    await r.save();
  }
}
