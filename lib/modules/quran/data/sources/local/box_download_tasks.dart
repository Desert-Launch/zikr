import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';

class BoxDownloadTasks extends HiveBoxBase<MDownloadTask> {
  BoxDownloadTasks() : super('quran_download_tasks');
}
