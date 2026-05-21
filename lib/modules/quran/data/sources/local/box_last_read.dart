import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';

class BoxLastRead extends HiveBoxBase<MLastRead> {
  BoxLastRead() : super('quran_last_read');

  static const int singletonKey = 0;
}
