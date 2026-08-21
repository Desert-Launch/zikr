import 'dart:convert';
import 'dart:io';

import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';

import 'sources.dart';

/// Assembles `assets/data/azkar_audio/readers.json` from `sources.dart` plus
/// the generated mapping files.
///
/// Counts are *computed* from the mappings, never typed by hand, so the
/// download manager can never advertise adhkar a reader does not actually have.
/// `verified` is only set for a reader whose every entry survived
/// `validate_audio.dart` — pass `--unverified` to stamp them anyway while
/// iterating locally (such a manifest must not be committed).
///
///   dart run tool/azkar_audio/generate_manifest.dart
Future<void> main(List<String> args) async {
  final force = args.contains('--unverified');
  final validation = File('docs/reports/adhkar-audio-validation.md');
  final validationRan = validation.existsSync();
  final validationText = validationRan ? await validation.readAsString() : '';
  final cleanRun = validationText.contains('## Problems (0)');

  if (!validationRan && !force) {
    stderr.writeln(
      'No validation report — run validate_audio.dart first, or pass '
      '--unverified for a local build.',
    );
    exitCode = 1;
    return;
  }

  final readers = <Map<String, dynamic>>[];
  for (final source in readerSources) {
    final file = File('assets/data/azkar_audio/mappings/${source.id}.json');
    if (!file.existsSync()) {
      stdout.writeln('  ! ${source.id}: no mapping file — omitted');
      continue;
    }
    final index = MAzkarReaderAudioIndex.fromJson(
      Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
    );
    if (index.isEmpty) {
      stdout.writeln('  ! ${source.id}: mapping is empty — omitted');
      continue;
    }
    final bytes = index.entries.fold<int>(
      0,
      (sum, e) => sum + (e.fileSize ?? 0),
    );
    readers.add(<String, dynamic>{
      'id': source.id,
      'nameAr': source.nameAr,
      'nameEn': source.nameEn,
      if (source.descriptionAr != null) 'descriptionAr': source.descriptionAr,
      if (source.descriptionEn != null) 'descriptionEn': source.descriptionEn,
      'sourceName': source.sourceName,
      'sourceUrl': source.sourceUrl,
      'license': source.license,
      'licenseStatus': source.licenseStatus.asJson,
      'attribution': source.attribution,
      'verified': force || cleanRun,
      'mappedAdhkar': index.singleCount,
      'categoryRecordings': index.categoryCount,
      'estimatedBytes': bytes,
    });
    stdout.writeln(
      '  ✓ ${source.id}: ${index.singleCount} adhkar, '
      '${index.categoryCount} category recordings, '
      '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB',
    );
  }

  final out = File('assets/data/azkar_audio/readers.json');
  await out.parent.create(recursive: true);
  await out.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'version': MAzkarAudioManifest.supportedVersion,
      'readers': readers,
    })}\n',
  );
  stdout.writeln('→ ${out.path} (${readers.length} readers)');
}
