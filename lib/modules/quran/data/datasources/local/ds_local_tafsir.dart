import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/sources/local/box_tafsir.dart';

/// Reads/writes downloaded tafsir books.
///
/// A book is stored as one small JSON file per surah
/// (`<documents>/tafsir/<bookId>/<surah>.json`, each `{ "surah:ayah": {...} }`),
/// so an ayah lookup reads and parses one surah instead of the whole book. The
/// box only keeps the small bookkeeping: the registry of downloaded ids, the
/// selected book and the seed marker.
///
/// Books used to live in the box itself as one multi-MB string each — and a
/// regular Hive box holds every value in memory from the moment it opens at
/// startup, so every downloaded book sat in RAM for the life of the process.
/// Those are moved out to files on first use (see [_migrateLegacyBlobs]).
///
/// Lets exceptions bubble — the repo converts them to [Failure]s.
class DSLocalTafsir {
  DSLocalTafsir(this._box);
  final BoxTafsir _box;

  /// Parsed surah slices, most recently used last (`bookId/surah` → entries).
  /// Bounded: a tafsir sheet reads one surah per downloaded book at a time.
  final LinkedHashMap<String, Map<String, dynamic>> _cache =
      LinkedHashMap<String, Map<String, dynamic>>();
  static const int _cacheSize = 8;

  /// Slices at least this large are decoded off the UI isolate.
  static const int _isolateThreshold = 64 * 1024;

  /// One migration per process, shared by every instance — the boot seed and
  /// the Quran module each build their own data source over the same box.
  static Future<void>? _migration;

  static String? _baseDir;

  Future<void> init() => _box.init();

  List<String> downloadedIds() {
    final raw = _box.box.get(BoxTafsir.registryKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }

  /// The registry is the source of truth: it is written only after a book's
  /// files are all in place.
  bool isDownloaded(String bookId) => downloadedIds().contains(bookId);

  /// Id of the book the viewer opens on, or null while the reader has not
  /// picked one (or picked one they later deleted).
  String? selectedId() {
    final id = _box.box.get(BoxTafsir.selectedKey);
    if (id == null || id.isEmpty) return null;
    // A book deleted after being picked must not keep steering the viewer.
    return isDownloaded(id) ? id : null;
  }

  Future<void> setSelected(String bookId) =>
      _box.box.put(BoxTafsir.selectedKey, bookId);

  /// Whether the default book's one-time seed has already run.
  bool isDefaultSeeded() => _box.box.containsKey(BoxTafsir.defaultSeededKey);

  /// Records that the seed is done, so it is never attempted again — including
  /// after the reader deletes the book from the library.
  Future<void> markDefaultSeeded() =>
      _box.box.put(BoxTafsir.defaultSeededKey, '1');

  /// Persists [jsonString] (a decoded book map) and registers [bookId].
  Future<void> saveBook(String bookId, String jsonString) async {
    await _ensureMigrated();
    await _writeBook(bookId, jsonString);
    final ids = downloadedIds().toSet()..add(bookId);
    await _box.box.put(BoxTafsir.registryKey, jsonEncode(ids.toList()));
  }

  Future<void> deleteBook(String bookId) async {
    await _ensureMigrated();
    final dir = Directory(await _bookDir(bookId));
    if (await dir.exists()) await dir.delete(recursive: true);
    if (_box.box.get(BoxTafsir.selectedKey) == bookId) {
      await _box.box.delete(BoxTafsir.selectedKey);
    }
    _evict(bookId);
    final ids = downloadedIds().toSet()..remove(bookId);
    await _box.box.put(BoxTafsir.registryKey, jsonEncode(ids.toList()));
  }

  /// [bookId]'s entries for [surah] (`{ "surah:ayah": {"text": ...} }`), or
  /// `null` when the book has nothing stored for it.
  Future<Map<String, dynamic>?> surahEntries(String bookId, int surah) async {
    await _ensureMigrated();
    final key = '$bookId/$surah';
    final cached = _cache.remove(key);
    if (cached != null) return _cache[key] = cached;

    final file = File(p.join(await _bookDir(bookId), '$surah.json'));
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    final map = raw.length >= _isolateThreshold
        ? await compute(_decodeEntries, raw)
        : _decodeEntries(raw);
    if (map == null) return null;
    _cache[key] = map;
    while (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return map;
  }

  /// Splits the book (off the UI isolate) and writes it under a temp directory
  /// that is renamed into place, so a crash mid-write never leaves a half book
  /// behind under its real name.
  Future<void> _writeBook(String bookId, String jsonString) async {
    final slices = await compute(_splitBySurah, jsonString);
    final dir = await _bookDir(bookId);
    final tmp = Directory('$dir.tmp');
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
    for (final slice in slices.entries) {
      await File(p.join(tmp.path, '${slice.key}.json')).writeAsString(slice.value, flush: true);
    }
    final target = Directory(dir);
    if (await target.exists()) await target.delete(recursive: true);
    await tmp.rename(dir);
    _evict(bookId);
  }

  void _evict(String bookId) =>
      _cache.removeWhere((key, _) => key.startsWith('$bookId/'));

  Future<String> _bookDir(String bookId) async {
    final base = _baseDir ??= p.join(
      (await getApplicationDocumentsDirectory()).path,
      'tafsir',
    );
    return p.join(base, bookId);
  }

  /// A failed migration (a full disk, say) must not take tafsir down with it:
  /// books already moved keep working, and the rest are retried next time.
  Future<void> _ensureMigrated() =>
      _migration ??= _migrateLegacyBlobs().catchError((Object e, StackTrace st) {
        _migration = null;
        AppLogger.error('Tafsir storage migration failed', error: e, stackTrace: st, tag: 'DSLocalTafsir');
      });

  /// Moves books stored the old way (`book::<id>` strings in the box) out to
  /// per-surah files, then compacts the box so the next launch no longer loads
  /// them. Each book is written in full before its key is deleted, so an
  /// interrupted run just picks up where it stopped.
  Future<void> _migrateLegacyBlobs() async {
    final legacy = _box.box.keys
        .whereType<String>()
        .where((k) => k.startsWith(BoxTafsir.legacyBookPrefix))
        .toList();
    if (legacy.isEmpty) return;
    for (final key in legacy) {
      final raw = _box.box.get(key);
      if (raw != null && raw.isNotEmpty) {
        await _writeBook(key.substring(BoxTafsir.legacyBookPrefix.length), raw);
      }
      await _box.box.delete(key);
    }
    await _box.box.compact();
  }
}

/// Groups a whole book's `"surah:ayah"` entries by surah and re-encodes each
/// group. Top-level and pure so it can run under [compute].
Map<int, String> _splitBySurah(String bookJson) {
  final decoded = jsonDecode(bookJson);
  if (decoded is! Map) return const {};
  final bySurah = <int, Map<String, dynamic>>{};
  decoded.forEach((key, value) {
    final surah = int.tryParse(key.toString().split(':').first);
    if (surah == null) return;
    (bySurah[surah] ??= <String, dynamic>{})[key.toString()] = value;
  });
  return {for (final e in bySurah.entries) e.key: jsonEncode(e.value)};
}

Map<String, dynamic>? _decodeEntries(String raw) {
  final decoded = jsonDecode(raw);
  return decoded is Map ? decoded.cast<String, dynamic>() : null;
}
