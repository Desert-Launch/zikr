import 'package:quran/core/utils/hive_box_base.dart';

/// Stores downloaded tafsir books as primitive `String` values.
///
/// Uses a primitive box (no [TypeAdapter]) on purpose — it sidesteps codegen and
/// survives the broken build_runner. Four kinds of keys live here:
///   • `book::<bookId>`     → the decompressed JSON blob for one book.
///   • `__downloaded__`     → JSON array of downloaded book ids (the registry).
///   • `__default_seeded__` → set once the default book has been fetched.
///   • `__selected__`       → id of the book the viewer opens on.
class BoxTafsir extends HiveBoxBase<String> {
  BoxTafsir() : super('quran_tafsir');

  static const String registryKey = '__downloaded__';

  /// Marks the one-time seed of the default book as done. Its presence is what
  /// stops a book the reader deleted on purpose from coming back next launch.
  static const String defaultSeededKey = '__default_seeded__';

  /// The book the per-ayah viewer opens on. Absent until the reader picks one
  /// in the library, in which case the default book is opened.
  static const String selectedKey = '__selected__';

  static String bookKey(String bookId) => 'book::$bookId';
}
