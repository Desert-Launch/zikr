import 'dart:convert';
import 'dart:io';

import 'package:quran/core/utils/arabic_normalizer.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

import 'adhkar_corpus.dart';
import 'http_util.dart';
import 'sources.dart';

/// Development-time audit of every mapping file.
///
/// Structural checks (ids, duplicates, dangling references) always run.
/// Network checks probe each URL and, with `--write`, fold the real
/// `Content-Length` back into the mapping so the download manager quotes a size
/// the user can trust. This is **not** wired into app startup: the app never
/// validates URLs at runtime, it just falls back when one fails.
///
/// `--prune` drops entries whose URL no longer answers with audio, so a source
/// that has gone away stops being advertised to users at all.
///
///   dart run tool/azkar_audio/validate_audio.dart [--offline] [--write] [--prune] [readerId ...]
Future<void> main(List<String> args) async {
  final offline = args.contains('--offline');
  final write = args.contains('--write');
  final prune = args.contains('--prune');
  final wanted = args.where((a) => !a.startsWith('--')).toSet();

  final corpus = await AdhkarCorpus.load();
  final adhkarIds = corpus.targets.map((t) => t.adhkarId).toSet();
  final adhkarText = <String, String>{
    for (final t in corpus.targets)
      t.adhkarId: ArabicNormalizer.normalize(t.text),
  };
  final readerIds = readerSources.map((r) => r.id).toSet();

  final dir = Directory('assets/data/azkar_audio/mappings');
  if (!dir.existsSync()) {
    stderr.writeln('No mappings — run match_adhkar.dart first.');
    exitCode = 1;
    return;
  }

  final problems = <String>[];
  var totalEntries = 0;
  var validUrls = 0;
  var brokenUrls = 0;
  var unprobed = 0;
  final confidence = <String, int>{};
  final seenUrls = <String, String>{};
  final ownerAdhkar = <String, String>{};

  final files =
      dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final json = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
    final index = MAzkarReaderAudioIndex.fromJson(json);
    if (wanted.isNotEmpty && !wanted.contains(index.readerId)) continue;

    if (!readerIds.contains(index.readerId)) {
      problems.add('${file.path}: readerId "${index.readerId}" is not in sources.dart');
    }
    if ((json['version'] as num?)?.toInt() != MAzkarAudioManifest.supportedVersion) {
      problems.add('${file.path}: version is not ${MAzkarAudioManifest.supportedVersion}');
    }

    final ids = <String>{};
    final rawEntries = (json['audio'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final entry in index.entries) {
      totalEntries++;
      confidence[entry.matchingConfidence.name] =
          (confidence[entry.matchingConfidence.name] ?? 0) + 1;

      if (!ids.add(entry.id)) {
        problems.add('${index.readerId}: duplicate entry id "${entry.id}"');
      }
      final dhikr = entry.adhkarId;
      if (entry.type == EAzkarAudioType.singleAdhkar) {
        if (dhikr == null || !adhkarIds.contains(dhikr)) {
          problems.add('${index.readerId}: unknown adhkarId "$dhikr"');
        }
      } else if (entry.categoryIds.isEmpty) {
        problems.add('${index.readerId}: category recording "${entry.id}" has no categories');
      }
      for (final cat in entry.categoryIds) {
        if (!corpus.categoryNames.containsKey(cat)) {
          problems.add('${index.readerId}: unknown categoryId "$cat" on "${entry.id}"');
        }
      }
      if (!entry.remoteUrl.startsWith('https://')) {
        problems.add('${index.readerId}: non-https url on "${entry.id}"');
      }
      final owner = seenUrls[entry.remoteUrl];
      if (owner != null && owner != entry.id) {
        // Two adhkar may legitimately share one recording when their text is
        // the *same words* — Ayat al-Kursi is in both the morning and the
        // evening list, and one recitation serves both. A shared URL across
        // adhkar whose normalised text differs is always a mapping bug.
        final mine = adhkarText[entry.adhkarId ?? ''] ?? '';
        final theirs = adhkarText[ownerAdhkar[owner] ?? ''] ?? '';
        if (entry.type == EAzkarAudioType.singleAdhkar &&
            ArabicNormalizer.similarity(mine, theirs) < 0.85) {
          problems.add(
            '${index.readerId}: url of "${entry.id}" duplicates "$owner" '
            'with different text',
          );
        }
      } else {
        seenUrls[entry.remoteUrl] = entry.id;
        ownerAdhkar[entry.id] = entry.adhkarId ?? '';
      }
    }

    if (offline) {
      unprobed += index.entries.length;
      continue;
    }

    stdout.writeln('Probing ${index.readerId} (${index.entries.length} files)…');
    final sizes = <String, int>{};
    final dead = <String>{};
    var done = 0;
    for (final entry in index.entries) {
      final probe = await HttpUtil.probe(entry.remoteUrl);
      if (probe.isAudio) {
        validUrls++;
        if (probe.contentLength > 0) sizes[entry.id] = probe.contentLength;
      } else {
        brokenUrls++;
        dead.add(entry.id);
        problems.add(
          '${index.readerId}: ${entry.id} → HTTP ${probe.statusCode} '
          '${probe.contentType.isEmpty ? (probe.error ?? '') : probe.contentType}',
        );
      }
      done++;
      stdout.write('\r  $done/${index.entries.length}');
    }
    stdout.writeln();

    if (!write && !prune) continue;
    var pruned = 0;
    if (prune && dead.isNotEmpty) {
      pruned = rawEntries.length;
      rawEntries.removeWhere((raw) => dead.contains('${raw['id']}'));
      pruned -= rawEntries.length;
    }
    if (write) {
      for (final raw in rawEntries) {
        final size = sizes['${raw['id']}'];
        if (size != null) raw['fileSize'] = size;
      }
    }
    if (sizes.isEmpty && pruned == 0) continue;
    json['audio'] = rawEntries;
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
    stdout.writeln(
      '  ↻ ${file.path}: ${write ? '${sizes.length} sizes' : 'unchanged sizes'}'
      '${pruned > 0 ? ', pruned $pruned dead' : ''}',
    );
  }

  final buffer = StringBuffer()
    ..writeln('# Adhkar audio source validation')
    ..writeln()
    ..writeln('Generated by `dart run tool/azkar_audio/validate_audio.dart`.')
    ..writeln()
    ..writeln('```text')
    ..writeln('Readers:       ${files.length}')
    ..writeln('Audio entries: $totalEntries')
    ..writeln()
    ..writeln('Valid URLs:    $validUrls')
    ..writeln('Broken:        $brokenUrls')
    ..writeln('Unprobed:      $unprobed');
  for (final e in confidence.entries) {
    buffer.writeln('${e.key.padRight(14)} ${e.value}');
  }
  buffer
    ..writeln('```')
    ..writeln()
    ..writeln('## Problems (${problems.length})')
    ..writeln();
  if (problems.isEmpty) {
    buffer.writeln('None.');
  } else {
    for (final p in problems.take(200)) {
      buffer.writeln('- $p');
    }
  }

  final out = File('docs/reports/adhkar-audio-validation.md');
  await out.parent.create(recursive: true);
  await out.writeAsString(buffer.toString());

  stdout
    ..writeln('Entries: $totalEntries | valid: $validUrls | broken: $brokenUrls')
    ..writeln('Problems: ${problems.length}')
    ..writeln('→ ${out.path}');
  for (final p in problems.take(25)) {
    stdout.writeln('  · $p');
  }
  HttpUtil.close();
  if (problems.isNotEmpty) exitCode = 1;
}
