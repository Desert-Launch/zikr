import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';

/// `assets/data/azkar_audio/readers.json` — the catalogue half of the manifest.
///
/// [version] lets a future build ship a changed schema without breaking an
/// installed app: the loader refuses a manifest it does not understand rather
/// than half-parsing it.
class MAzkarAudioManifest extends Equatable {
  const MAzkarAudioManifest({
    required this.version,
    required this.readers,
    this.generatedAt,
  });

  /// Schema revision this build of the app knows how to read.
  static const int supportedVersion = 1;

  factory MAzkarAudioManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['readers'] as List<dynamic>? ?? const <dynamic>[];
    return MAzkarAudioManifest(
      version: (json['version'] as num?)?.toInt() ?? 0,
      generatedAt: json['generatedAt'] as String?,
      readers: raw
          .map((e) => MAzkarReader.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }

  const MAzkarAudioManifest.empty()
    : version = supportedVersion,
      generatedAt = null,
      readers = const <MAzkarReader>[];

  final int version;
  final String? generatedAt;
  final List<MAzkarReader> readers;

  bool get isSupported => version > 0 && version <= supportedVersion;

  /// Readers safe to show: verified by the validator and actually carrying
  /// audio. Keeps a half-imported reader out of the UI (sources doc §35).
  List<MAzkarReader> get usable =>
      readers.where((r) => r.verified && r.hasAnyAudio).toList(growable: false);

  @override
  List<Object?> get props => [version, readers];
}

/// One reader's mapping file, indexed for O(1) lookup by dhikr and category.
class MAzkarReaderAudioIndex extends Equatable {
  MAzkarReaderAudioIndex({required this.readerId, required this.entries})
    : byAdhkarId = <String, MAzkarAudio>{
        for (final e in entries)
          if (!e.isCategoryRecording && (e.adhkarId?.isNotEmpty ?? false))
            e.adhkarId ?? '': e,
      },
      categoryRecordings = <String, List<MAzkarAudio>>{} {
    for (final e in entries) {
      if (!e.isCategoryRecording) continue;
      for (final cat in e.categoryIds) {
        categoryRecordings.putIfAbsent(cat, () => <MAzkarAudio>[]).add(e);
      }
    }
  }

  MAzkarReaderAudioIndex.empty(String readerId)
    : this(readerId: readerId, entries: const <MAzkarAudio>[]);

  factory MAzkarReaderAudioIndex.fromJson(Map<String, dynamic> json) {
    final readerId = json['readerId'] as String? ?? '';
    final raw = json['audio'] as List<dynamic>? ?? const <dynamic>[];
    final entries = raw
        .map(
          (e) => MAzkarAudio.fromJson(
            Map<String, dynamic>.from(e as Map),
            readerId,
          ),
        )
        // An entry whose provenance was never established must not play.
        .where((e) => e.matchingConfidence.isPlayable && e.remoteUrl.isNotEmpty)
        .toList(growable: false);
    return MAzkarReaderAudioIndex(readerId: readerId, entries: entries);
  }

  final String readerId;
  final List<MAzkarAudio> entries;

  /// Individual recordings keyed by the app's `MAzkarItem.id`.
  final Map<String, MAzkarAudio> byAdhkarId;

  /// Whole-sitting recordings keyed by app category id. A recording covering
  /// two sittings appears under both keys — one file, two entry points.
  final Map<String, List<MAzkarAudio>> categoryRecordings;

  MAzkarAudio? forAdhkar(String adhkarId) => byAdhkarId[adhkarId];

  List<MAzkarAudio> forCategory(String categoryId) =>
      categoryRecordings[categoryId] ?? const <MAzkarAudio>[];

  /// Individual recordings belonging to [categoryId], in manifest order.
  List<MAzkarAudio> singlesInCategory(String categoryId) => entries
      .where((e) => !e.isCategoryRecording && e.categoryIds.contains(categoryId))
      .toList(growable: false);

  /// Every category id this reader touches, individual or whole-sitting.
  Set<String> get categoryIds =>
      entries.expand((e) => e.categoryIds).toSet();

  int get singleCount => byAdhkarId.length;

  int get categoryCount =>
      entries.where((e) => e.isCategoryRecording).length;

  bool get isEmpty => entries.isEmpty;

  @override
  List<Object?> get props => [readerId, entries];
}
