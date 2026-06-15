import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/data/sources/local/box_bookmarks.dart';
import 'package:quran/modules/quran/data/sources/local/box_last_read.dart';

class DSLocalBookmarks {
  DSLocalBookmarks(this._bookmarks, this._lastRead);
  final BoxBookmarks _bookmarks;
  final BoxLastRead _lastRead;

  Future<void> init() async {
    await _bookmarks.init();
    await _lastRead.init();
  }

  Future<void> putBookmark(MBookmark bookmark) async {
    await _bookmarks.box.put(bookmark.id, bookmark);
  }

  Future<void> deleteBookmark(String id) async {
    await _bookmarks.box.delete(id);
  }

  List<MBookmark> listBookmarks() => _bookmarks.box.values.toList(growable: false);

  /// Emits the full bookmark list whenever the box changes (add/update/delete),
  /// so listeners can react instantly without re-querying.
  Stream<List<MBookmark>> watchBookmarks() =>
      _bookmarks.box.watch().map((_) => listBookmarks());

  Future<void> putLastRead(MLastRead value) async {
    await _lastRead.box.put(BoxLastRead.singletonKey, value);
  }

  MLastRead? getLastRead() => _lastRead.box.get(BoxLastRead.singletonKey);
}
