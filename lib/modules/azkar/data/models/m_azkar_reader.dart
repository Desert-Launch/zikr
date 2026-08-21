import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

/// A reciter of adhkar audio, as declared in `assets/data/azkar_audio/readers.json`.
///
/// The counts are *not* advertising copy — they are written by the build-time
/// matcher from the reader's mapping file, so `mappedAdhkar` only ever counts
/// adhkar that exist in this app and resolve to a playable URL.
class MAzkarReader extends Equatable {
  const MAzkarReader({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sourceName,
    required this.sourceUrl,
    required this.license,
    required this.licenseStatus,
    required this.attribution,
    required this.verified,
    required this.mappedAdhkar,
    required this.categoryRecordings,
    required this.estimatedBytes,
    this.imageUrl,
    this.descriptionAr,
    this.descriptionEn,
  });

  factory MAzkarReader.fromJson(Map<String, dynamic> json) => MAzkarReader(
    id: json['id'] as String? ?? '',
    nameAr: json['nameAr'] as String? ?? '',
    nameEn: json['nameEn'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    descriptionAr: json['descriptionAr'] as String?,
    descriptionEn: json['descriptionEn'] as String?,
    sourceName: json['sourceName'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    license: json['license'] as String? ?? '',
    licenseStatus: EAzkarLicenseStatus.fromJson(json['licenseStatus'] as String?),
    attribution: json['attribution'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    mappedAdhkar: (json['mappedAdhkar'] as num?)?.toInt() ?? 0,
    categoryRecordings: (json['categoryRecordings'] as num?)?.toInt() ?? 0,
    estimatedBytes: (json['estimatedBytes'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final String? descriptionAr;
  final String? descriptionEn;

  /// Where the recordings come from, e.g. `حصن المسلم` / `archive.org`.
  final String sourceName;
  final String sourceUrl;

  /// Free-text licence note kept alongside [licenseStatus].
  final String license;
  final EAzkarLicenseStatus licenseStatus;

  /// Credit line shown in the reader detail screen.
  final String attribution;

  /// Set by `validate_audio.dart` once every URL answered with real audio.
  /// A reader that is not verified is never surfaced in the UI.
  final bool verified;

  /// How many of *this app's* adhkar this reader has an individual file for.
  final int mappedAdhkar;

  /// How many whole-sitting recordings this reader contributes.
  final int categoryRecordings;

  /// Sum of the `fileSize` recorded for every entry, for the download estimate.
  final int estimatedBytes;

  bool get hasAnyAudio => mappedAdhkar > 0 || categoryRecordings > 0;

  double get estimatedMegabytes => estimatedBytes / 1024 / 1024;

  String displayName(bool isArabic) =>
      isArabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);

  String? description(bool isArabic) =>
      isArabic ? descriptionAr : (descriptionEn ?? descriptionAr);

  @override
  List<Object?> get props => [id];
}
