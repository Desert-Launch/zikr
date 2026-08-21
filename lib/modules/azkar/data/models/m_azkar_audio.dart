import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

/// One playable recording, as declared in a reader's mapping file.
///
/// The link back to the app is [adhkarId] (an existing `MAzkarItem.id`) for a
/// single dhikr, or [categoryIds] for a whole-sitting recording. The app's
/// adhkar data is never touched — this is a side table keyed by its ids.
class MAzkarAudio extends Equatable {
  const MAzkarAudio({
    required this.id,
    required this.readerId,
    required this.type,
    required this.remoteUrl,
    required this.matchingConfidence,
    required this.categoryIds,
    this.adhkarId,
    this.titleAr,
    this.durationSeconds,
    this.fileSize,
    this.sourceUrl,
  });

  factory MAzkarAudio.fromJson(Map<String, dynamic> json, String readerId) {
    final rawCats = json['categoryIds'] as List<dynamic>?;
    return MAzkarAudio(
      id: json['id'] as String? ?? '',
      readerId: readerId,
      type: EAzkarAudioType.fromJson(json['audioType'] as String?),
      adhkarId: json['adhkarId'] as String?,
      categoryIds: rawCats == null
          ? const <String>[]
          : rawCats.map((e) => e.toString()).toList(growable: false),
      titleAr: json['titleAr'] as String?,
      remoteUrl: json['remoteUrl'] as String? ?? '',
      durationSeconds: (json['duration'] as num?)?.toInt(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      sourceUrl: json['sourceUrl'] as String?,
      matchingConfidence: EAzkarAudioMatch.fromJson(
        json['matchingConfidence'] as String?,
      ),
    );
  }

  /// Globally unique: `<readerId>:<adhkarId>` or `<readerId>:cat:<slug>`.
  final String id;
  final String readerId;
  final EAzkarAudioType type;

  /// The app dhikr this file recites. Null for a category recording.
  final String? adhkarId;

  /// Categories this file belongs to. One entry for a single dhikr (its owning
  /// category); one *or more* for a category recording — a file titled
  /// "أذكار الصباح والمساء" genuinely covers two sittings, and listing both is
  /// honest where splitting it would be a fabrication.
  final List<String> categoryIds;

  /// Display title for a category recording (the source's own wording).
  final String? titleAr;

  final String remoteUrl;
  final int? durationSeconds;
  final int? fileSize;

  /// Human-facing page the file came from, for attribution.
  final String? sourceUrl;

  final EAzkarAudioMatch matchingConfidence;

  bool get isCategoryRecording => type.isCategory;

  /// Filename stem under the reader's download directory. Derived from ids
  /// only, so the same entry always lands on the same path.
  String get fileStem {
    final dhikr = adhkarId;
    if (dhikr != null && dhikr.isNotEmpty) return _sanitize(dhikr);
    final tail = id.split(':').last;
    return 'cat_${_sanitize(tail)}';
  }

  static String _sanitize(String raw) =>
      raw.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'audioType': type.asJson,
    if (adhkarId != null) 'adhkarId': adhkarId,
    'categoryIds': categoryIds,
    if (titleAr != null) 'titleAr': titleAr,
    'remoteUrl': remoteUrl,
    if (durationSeconds != null) 'duration': durationSeconds,
    if (fileSize != null) 'fileSize': fileSize,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
    'matchingConfidence': matchingConfidence.asJson,
  };

  @override
  List<Object?> get props => [id];
}
