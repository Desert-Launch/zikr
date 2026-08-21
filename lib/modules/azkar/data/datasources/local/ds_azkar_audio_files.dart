import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';

/// Filesystem layer for downloaded adhkar audio.
///
/// Layout mirrors the Qur'an module's (`DSLocalAudioFiles`):
///   `{app_documents}/azkar_audio/{readerId}/{fileStem}.mp3`
///
/// Bytes land in a sibling `.part` file and are only renamed into place on
/// success, so a truncated transfer can never be mistaken for a finished
/// download — and the `.part` is what a resumed transfer appends to.
class DSAzkarAudioFiles {
  DSAzkarAudioFiles();

  static const String rootDirName = 'azkar_audio';
  static const String partSuffix = '.part';

  String? _baseCache;

  Future<String> baseDir() async {
    final cached = _baseCache;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final base = p.join(docs.path, rootDirName);
    final dir = Directory(base);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _baseCache = base;
    return base;
  }

  Future<String> pathFor(MAzkarAudio audio) async {
    final base = await baseDir();
    return p.join(base, audio.readerId, '${audio.fileStem}.mp3');
  }

  Future<String> partPathFor(MAzkarAudio audio) async =>
      '${await pathFor(audio)}$partSuffix';

  Future<bool> exists(MAzkarAudio audio) async =>
      File(await pathFor(audio)).exists();

  Future<int> sizeOf(MAzkarAudio audio) async {
    final file = File(await pathFor(audio));
    if (!await file.exists()) return 0;
    return file.length();
  }

  /// Bytes already sitting in the `.part` file, i.e. where a resumed transfer
  /// should continue from. Zero when there is nothing to resume.
  Future<int> partialBytes(MAzkarAudio audio) async {
    final file = File(await partPathFor(audio));
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<void> ensureReaderDir(String readerId) async {
    final base = await baseDir();
    final dir = Directory(p.join(base, readerId));
    if (!dir.existsSync()) await dir.create(recursive: true);
  }

  Future<bool> readerDirExists(String readerId) async {
    final base = await baseDir();
    return Directory(p.join(base, readerId)).exists();
  }

  Future<int> bytesForReader(String readerId) async {
    final base = await baseDir();
    final dir = Directory(p.join(base, readerId));
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && !entity.path.endsWith(partSuffix)) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<int> totalBytes() async {
    final dir = Directory(await baseDir());
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && !entity.path.endsWith(partSuffix)) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> delete(MAzkarAudio audio) async {
    for (final path in <String>[
      await pathFor(audio),
      await partPathFor(audio),
    ]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> deleteReader(String readerId) async {
    final base = await baseDir();
    final dir = Directory(p.join(base, readerId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteAll() async {
    final dir = Directory(await baseDir());
    if (await dir.exists()) await dir.delete(recursive: true);
    _baseCache = null;
  }

  /// Clears leftover `.part` files for a reader — used after a cancelled run so
  /// an abandoned transfer does not sit on disk forever.
  Future<void> clearPartials(String readerId) async {
    final base = await baseDir();
    final dir = Directory(p.join(base, readerId));
    if (!await dir.exists()) return;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith(partSuffix)) {
        await entity.delete();
      }
    }
  }
}
