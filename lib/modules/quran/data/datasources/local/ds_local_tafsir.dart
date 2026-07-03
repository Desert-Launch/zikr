import 'dart:convert';

import 'package:quran/modules/quran/data/sources/local/box_tafsir.dart';

/// Reads/writes downloaded tafsir books in the local box.
///
/// Each book is persisted as a single decompressed JSON string keyed by
/// `book::<id>`; the set of downloaded ids is kept in a small JSON registry.
/// Parsed book maps are cached in memory so an ayah lookup does not re-decode
/// the whole (6236-entry) book on every tap. Lets exceptions bubble — the repo
/// converts them to [Failure]s.
class DSLocalTafsir {
  DSLocalTafsir(this._box);
  final BoxTafsir _box;

  /// bookId -> parsed `{ "surah:ayah": {"text": ...} }` map.
  final Map<String, Map<String, dynamic>> _cache = {};

  Future<void> init() => _box.init();

  List<String> downloadedIds() {
    final raw = _box.box.get(BoxTafsir.registryKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }

  bool isDownloaded(String bookId) => _box.box.containsKey(BoxTafsir.bookKey(bookId));

  /// Persists [jsonString] (a decoded book map) and registers [bookId].
  Future<void> saveBook(String bookId, String jsonString) async {
    await _box.box.put(BoxTafsir.bookKey(bookId), jsonString);
    _cache.remove(bookId);
    final ids = downloadedIds().toSet()..add(bookId);
    await _box.box.put(BoxTafsir.registryKey, jsonEncode(ids.toList()));
  }

  Future<void> deleteBook(String bookId) async {
    await _box.box.delete(BoxTafsir.bookKey(bookId));
    _cache.remove(bookId);
    final ids = downloadedIds().toSet()..remove(bookId);
    await _box.box.put(BoxTafsir.registryKey, jsonEncode(ids.toList()));
  }

  /// Parsed map for [bookId], or `null` if the book is not stored. Cached after
  /// the first access.
  Map<String, dynamic>? bookMap(String bookId) {
    final cached = _cache[bookId];
    if (cached != null) return cached;
    final raw = _box.box.get(BoxTafsir.bookKey(bookId));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = decoded.cast<String, dynamic>();
    _cache[bookId] = map;
    return map;
  }
}
