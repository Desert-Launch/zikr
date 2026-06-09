import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_download.dart';

class BoxAdhanDownload extends HiveBoxBase<MAdhanDownload> {
  BoxAdhanDownload() : super('adhan_downloads');

  MAdhanDownload? byId(String voiceId) => box.get(voiceId);

  bool isDownloaded(String voiceId) => box.get(voiceId)?.downloaded ?? false;

  String? localPath(String voiceId) {
    final rec = box.get(voiceId);
    return (rec?.downloaded ?? false) ? rec?.localPath : null;
  }

  Future<void> save(MAdhanDownload record) async {
    await box.put(record.voiceId, record);
  }

  Future<void> remove(String voiceId) async {
    await box.delete(voiceId);
  }

  List<MAdhanDownload> all() => box.values.toList(growable: false);
}
