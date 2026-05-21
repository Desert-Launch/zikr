import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/quran/data/models/m_reciter_pref.dart';

class BoxReciterPref extends HiveBoxBase<MReciterPref> {
  BoxReciterPref() : super('quran_reciter_pref');

  static const int singletonKey = 0;
}
