import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';

/// Loads the bundled adhkar-audio manifest.
///
/// Deliberately lazy, because the manifest grows with every reader added:
/// `readers.json` is small and always parsed, while a reader's mapping file is
/// only read the first time something asks about that reader. Playing a dhikr
/// with a preferred reader therefore parses exactly one mapping file, not
/// eleven. [loadAll] exists for the screens that genuinely need the whole
/// picture (the reader picker and the download manager).
class DSLocalAzkarAudio {
  DSLocalAzkarAudio();

  static const String _dir = 'assets/data/azkar_audio';
  static const String _manifestFile = '$_dir/readers.json';

  MAzkarAudioManifest? _manifest;
  final Map<String, MAzkarReaderAudioIndex> _indexes =
      <String, MAzkarReaderAudioIndex>{};

  /// Readers that are verified and actually carry audio.
  ///
  /// A manifest whose `version` this build does not understand yields an empty
  /// list rather than a partial parse — an app that shipped before a schema
  /// change simply shows no readers instead of misreading the new shape.
  Future<List<MAzkarReader>> readers() async {
    final manifest = await _loadManifest();
    return manifest.usable;
  }

  Future<MAzkarAudioManifest> _loadManifest() async {
    final cached = _manifest;
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(_manifestFile);
      final parsed = MAzkarAudioManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (!parsed.isSupported) {
        AppLogger.warning(
          'Adhkar audio manifest version ${parsed.version} is newer than this '
          'build supports (${MAzkarAudioManifest.supportedVersion}) — '
          'ignoring it',
          tag: 'DSLocalAzkarAudio',
        );
        _manifest = const MAzkarAudioManifest.empty();
        return _manifest ?? const MAzkarAudioManifest.empty();
      }
      _manifest = parsed;
      return parsed;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load the adhkar audio manifest',
        tag: 'DSLocalAzkarAudio',
        error: e,
        stackTrace: st,
      );
      _manifest = const MAzkarAudioManifest.empty();
      return _manifest ?? const MAzkarAudioManifest.empty();
    }
  }

  /// One reader's indexed mapping file. Cached after the first read.
  Future<MAzkarReaderAudioIndex> indexFor(String readerId) async {
    final cached = _indexes[readerId];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString('$_dir/mappings/$readerId.json');
      final index = MAzkarReaderAudioIndex.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      _indexes[readerId] = index;
      return index;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load the audio mapping for "$readerId"',
        tag: 'DSLocalAzkarAudio',
        error: e,
        stackTrace: st,
      );
      final empty = MAzkarReaderAudioIndex.empty(readerId);
      _indexes[readerId] = empty;
      return empty;
    }
  }

  /// Parses every reader's mapping file. Only for screens that compare readers.
  Future<Map<String, MAzkarReaderAudioIndex>> loadAll() async {
    for (final reader in await readers()) {
      await indexFor(reader.id);
    }
    return Map<String, MAzkarReaderAudioIndex>.unmodifiable(_indexes);
  }

  /// Already-parsed index, without triggering a load. Lets synchronous UI paths
  /// (a list item's play button) read what is in memory and stay cheap.
  MAzkarReaderAudioIndex? cachedIndex(String readerId) => _indexes[readerId];

  /// This reader's recording of [adhkarId], if the mapping is already parsed.
  Future<MAzkarAudio?> audioForAdhkar(String readerId, String adhkarId) async {
    final index = await indexFor(readerId);
    return index.forAdhkar(adhkarId);
  }

  /// This reader's whole-sitting recordings for [categoryId].
  Future<List<MAzkarAudio>> categoryRecordings(
    String readerId,
    String categoryId,
  ) async {
    final index = await indexFor(readerId);
    return index.forCategory(categoryId);
  }

  /// Every file this reader offers, individual and whole-sitting.
  Future<List<MAzkarAudio>> allFor(String readerId) async {
    final index = await indexFor(readerId);
    return index.entries;
  }
}
