import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';

class BoxBookmarks extends HiveBoxBase<MBookmark> {
  BoxBookmarks() : super('quran_bookmarks');
}
