import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Filesystem layer for downloaded audio files.
///
/// Layout:
///   {app_documents}/quran_audio/{reciterId}/{surah:3}/{ayah:3}.mp3
class DSLocalAudioFiles {
  DSLocalAudioFiles();

  String? _baseCache;

  Future<String> _baseDir() async {
    if (_baseCache != null) return _baseCache!;
    final docs = await getApplicationDocumentsDirectory();
    final base = p.join(docs.path, 'quran_audio');
    final dir = Directory(base);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _baseCache = base;
    return base;
  }

  Future<String> pathFor(String reciterId, int surah, int ayah) async {
    final base = await _baseDir();
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return p.join(base, reciterId, s, '$a.mp3');
  }

  Future<bool> exists(String reciterId, int surah, int ayah) async {
    final f = File(await pathFor(reciterId, surah, ayah));
    return f.exists();
  }

  Future<int> sizeOf(String reciterId, int surah, int ayah) async {
    final f = File(await pathFor(reciterId, surah, ayah));
    if (!await f.exists()) return 0;
    return f.length();
  }

  /// Counts how many `*.mp3` ayah files exist on disk for [surah].
  /// Used for disk-as-truth status reporting — no separate flag needed.
  Future<int> countDownloaded(String reciterId, int surah) async {
    final base = await _baseDir();
    final s = surah.toString().padLeft(3, '0');
    final dir = Directory(p.join(base, reciterId, s));
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final e in dir.list(followLinks: false)) {
      if (e is File && e.path.endsWith('.mp3')) count++;
    }
    return count;
  }

  /// True when any audio has been downloaded for [reciterId]. Cheap guard that
  /// lets callers skip a full per-surah scan for reciters with nothing on disk.
  Future<bool> reciterDirExists(String reciterId) async {
    final base = await _baseDir();
    return Directory(p.join(base, reciterId)).exists();
  }

  /// Total bytes on disk for a single reciter (0 when nothing downloaded).
  Future<int> bytesForReciter(String reciterId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, reciterId));
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<void> ensureDir(String reciterId, int surah) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, reciterId, surah.toString().padLeft(3, '0')));
    if (!dir.existsSync()) await dir.create(recursive: true);
  }

  Future<void> deleteForSurah(String reciterId, int surah) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, reciterId, surah.toString().padLeft(3, '0')));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteForReciter(String reciterId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, reciterId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<int> totalBytes() async {
    final base = await _baseDir();
    final dir = Directory(base);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
