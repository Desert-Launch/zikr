import 'dart:convert';
import 'dart:io';

import 'package:quran/core/utils/arabic_normalizer.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/services/azkar_audio_matcher.dart';

import 'adhkar_corpus.dart';
import 'sources.dart';

/// Builds `assets/data/azkar_audio/mappings/<reader>.json` from the imported
/// raw data, and writes an audit report of everything it refused to map.
///
/// The app's adhkar are the source of truth throughout: nothing here writes to
/// `assets/data/azkar/`, and an external record that cannot be tied to an
/// existing dhikr id is dropped, never added.
///
///   dart run tool/azkar_audio/match_adhkar.dart
Future<void> main(List<String> args) async {
  final corpus = await AdhkarCorpus.load();
  stdout.writeln('App adhkar: ${corpus.targets.length}');

  final reports = <String, _ReaderReport>{};

  for (final reader in readerSources) {
    final entries = <MAzkarAudio>[];
    final report = _ReaderReport(reader.id);

    if (reader.hisnMuslim) {
      await _buildHisnMuslim(reader, corpus, entries, report);
    }
    if (reader.archiveItems.isNotEmpty) {
      await _buildArchive(reader, corpus, entries, report);
    }

    if (entries.isEmpty) {
      stdout.writeln('  ! ${reader.id}: nothing mapped — skipping');
      continue;
    }
    await _writeMapping(reader.id, entries);
    reports[reader.id] = report;
    stdout.writeln(
      '  ✓ ${reader.id}: ${report.singles} individual, '
      '${report.categories} category recordings',
    );
  }

  await _writeReport(reports, corpus);
}

// ---------------------------------------------------------------------------
// Hisn al-Muslim — per-dhikr audio, matched by text
// ---------------------------------------------------------------------------

Future<void> _buildHisnMuslim(
  ReaderSource reader,
  AdhkarCorpus corpus,
  List<MAzkarAudio> out,
  _ReaderReport report,
) async {
  final file = File('tool/azkar_audio/raw/hisn_muslim.json');
  if (!file.existsSync()) {
    stdout.writeln('  ! ${reader.id}: run import_hisn_muslim.dart first');
    return;
  }
  final raw = Map<String, dynamic>.from(
    jsonDecode(await file.readAsString()) as Map,
  );
  final chapters = (raw['categories'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);

  // --- individual adhkar -----------------------------------------------
  final candidates = <AzkarMatchCandidate>[];
  final audioById = <String, String>{};
  for (final chapter in chapters) {
    final title = chapter['title'] as String? ?? '';
    for (final e in chapter['entries'] as List<dynamic>) {
      final map = Map<String, dynamic>.from(e as Map);
      final id = '${map['id']}';
      audioById[id] = map['audio'] as String? ?? '';
      candidates.add(
        AzkarMatchCandidate(
          sourceId: id,
          text: map['text'] as String? ?? '',
          categoryName: title,
          audioUrl: map['audio'] as String?,
        ),
      );
    }
  }
  report.sourceRecords = candidates.length;

  final matcher = AzkarAudioMatcher(manualOverrides: reader.manualOverrides);
  final results = matcher.matchAll(corpus.targets, candidates);

  for (final r in results) {
    report.count(r.reason);
    final candidate = r.candidate;
    if (candidate == null || !r.isAccepted) {
      if (r.reason != AzkarMatchReason.noCandidate) {
        report.rejected.add(<String, dynamic>{
          'adhkarId': r.target.adhkarId,
          'categoryId': r.target.categoryId,
          'reason': r.reason.name,
          'score': double.parse(r.score.toStringAsFixed(3)),
          'appText': _clip(r.target.text),
          'bestCandidateText': _clip(r.runnerUp?.text ?? ''),
        });
      } else {
        report.unmatched.add(<String, dynamic>{
          'adhkarId': r.target.adhkarId,
          'categoryId': r.target.categoryId,
          'appText': _clip(r.target.text),
        });
      }
      continue;
    }
    out.add(
      MAzkarAudio(
        id: '${reader.id}:${r.target.adhkarId}',
        readerId: reader.id,
        type: EAzkarAudioType.singleAdhkar,
        adhkarId: r.target.adhkarId,
        categoryIds: <String>[r.target.categoryId],
        remoteUrl: audioById[candidate.sourceId] ?? '',
        sourceUrl: reader.sourceUrl,
        matchingConfidence: r.confidence,
      ),
    );
    report.singles++;
  }

  // --- whole-chapter recordings ----------------------------------------
  for (final chapter in chapters) {
    final url = chapter['audioUrl'] as String? ?? '';
    if (url.isEmpty) continue;
    final title = chapter['title'] as String? ?? '';
    final mapped = _mapChapterToCategories(title, corpus.categoryNames);
    if (mapped == null) {
      report.unmappedChapters.add(title);
      continue;
    }
    out.add(
      MAzkarAudio(
        id: '${reader.id}:cat:${chapter['id']}',
        readerId: reader.id,
        type: EAzkarAudioType.categoryRecording,
        categoryIds: mapped.categoryIds,
        titleAr: title,
        remoteUrl: url,
        sourceUrl: reader.sourceUrl,
        matchingConfidence: mapped.confidence,
      ),
    );
    report.categories++;
  }
}

// ---------------------------------------------------------------------------
// archive.org — whole-sitting recordings, categories declared by hand
// ---------------------------------------------------------------------------

Future<void> _buildArchive(
  ReaderSource reader,
  AdhkarCorpus corpus,
  List<MAzkarAudio> out,
  _ReaderReport report,
) async {
  final file = File('tool/azkar_audio/raw/archive_items.json');
  if (!file.existsSync()) {
    stdout.writeln('  ! ${reader.id}: run import_archive_reader.dart first');
    return;
  }
  final raw = Map<String, dynamic>.from(
    jsonDecode(await file.readAsString()) as Map,
  );
  final entries = (raw[reader.id] as List<dynamic>? ?? const <dynamic>[])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
  report.sourceRecords += entries.length;

  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final categoryIds = (e['categoryIds'] as List<dynamic>)
        .map((c) => c.toString())
        .where(corpus.categoryNames.containsKey)
        .toList(growable: false);
    if (categoryIds.isEmpty) {
      report.unmappedChapters.add('${e['titleAr']}');
      continue;
    }
    out.add(
      MAzkarAudio(
        id: '${reader.id}:cat:${e['itemId']}_$i',
        readerId: reader.id,
        type: EAzkarAudioType.categoryRecording,
        categoryIds: categoryIds,
        titleAr: e['titleAr'] as String?,
        remoteUrl: e['url'] as String? ?? '',
        durationSeconds: (e['duration'] as num?)?.toInt(),
        fileSize: (e['fileSize'] as num?)?.toInt(),
        sourceUrl: e['sourceUrl'] as String?,
        // A human read the item's file title and wrote the sitting down in
        // sources.dart — that is exactly what `manual` means.
        matchingConfidence: EAzkarAudioMatch.manual,
      ),
    );
    report.categories++;
  }
}

// ---------------------------------------------------------------------------

class _ChapterMapping {
  const _ChapterMapping(this.categoryIds, this.confidence);
  final List<String> categoryIds;
  final EAzkarAudioMatch confidence;
}

/// Ties a source chapter title to app category ids.
///
/// Exact normalised title equality is the happy path. A title naming *both*
/// sittings ("أذكار الصباح والمساء") legitimately covers two app categories, so
/// it attaches to each — that is the file's real content, not a fabricated
/// split. Anything else needs one clear winner or it is dropped.
_ChapterMapping? _mapChapterToCategories(
  String title,
  Map<String, String> appCategories,
) {
  final normalized = ArabicNormalizer.normalize(title);
  if (normalized.isEmpty) return null;

  final exact = appCategories.entries
      .where((e) => ArabicNormalizer.normalize(e.value) == normalized)
      .map((e) => e.key)
      .toList(growable: false);
  if (exact.isNotEmpty) {
    return _ChapterMapping(exact, EAzkarAudioMatch.exact);
  }

  final markers = ArabicNormalizer.temporalMarkers(title);
  if (markers.length > 1) {
    final chapterTokens = ArabicNormalizer.tokens(title).toSet();
    final combined = appCategories.entries.where((e) {
      final own = ArabicNormalizer.temporalMarkers(e.value);
      if (own.length != 1 || !markers.contains(own.first)) return false;
      // Every *non-time* word of the app category must also appear in the
      // chapter title. A plain similarity floor fails here: "أذكار المساء"
      // shares only one token with "أذكار الصباح والمساء" because the second
      // carries a waw prefix, yet it is unmistakably the same sitting.
      // "أذكار النوم" contributes "النوم", which the title lacks, so it is
      // correctly left out.
      return ArabicNormalizer.tokens(e.value)
          .where((t) => ArabicNormalizer.temporalMarkers(t).isEmpty)
          .every(chapterTokens.contains);
    }).map((e) => e.key).toList(growable: false);
    if (combined.isNotEmpty) {
      return _ChapterMapping(combined, EAzkarAudioMatch.high);
    }
  }

  final scored =
      appCategories.entries
          .map((e) => (id: e.key, s: ArabicNormalizer.similarity(title, e.value)))
          .toList()
        ..sort((a, b) => b.s.compareTo(a.s));
  final best = scored.first;
  final second = scored.length > 1 ? scored[1].s : 0.0;
  if (best.s >= 0.9 && (best.s - second) >= 0.05) {
    return _ChapterMapping(<String>[best.id], EAzkarAudioMatch.high);
  }
  return null;
}

Future<void> _writeMapping(String readerId, List<MAzkarAudio> entries) async {
  final out = File('assets/data/azkar_audio/mappings/$readerId.json');
  await out.parent.create(recursive: true);
  await out.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'version': 1,
      'readerId': readerId,
      'audio': entries.map((e) => e.toJson()).toList(growable: false),
    })}\n',
  );
}

class _ReaderReport {
  _ReaderReport(this.readerId);
  final String readerId;
  int sourceRecords = 0;
  int singles = 0;
  int categories = 0;
  final Map<String, int> reasons = <String, int>{};
  final List<Map<String, dynamic>> rejected = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> unmatched = <Map<String, dynamic>>[];
  final List<String> unmappedChapters = <String>[];

  void count(AzkarMatchReason reason) =>
      reasons[reason.name] = (reasons[reason.name] ?? 0) + 1;
}

Future<void> _writeReport(
  Map<String, _ReaderReport> reports,
  AdhkarCorpus corpus,
) async {
  final buffer = StringBuffer()
    ..writeln('# Adhkar audio mapping report')
    ..writeln()
    ..writeln('Generated by `dart run tool/azkar_audio/match_adhkar.dart`.')
    ..writeln()
    ..writeln('App adhkar in corpus: **${corpus.targets.length}**')
    ..writeln('App categories: **${corpus.categoryNames.length}**')
    ..writeln();

  for (final report in reports.values) {
    buffer
      ..writeln('## ${report.readerId}')
      ..writeln()
      ..writeln('| metric | count |')
      ..writeln('| --- | --- |')
      ..writeln('| source records | ${report.sourceRecords} |')
      ..writeln('| mapped individual adhkar | ${report.singles} |')
      ..writeln('| category recordings | ${report.categories} |');
    for (final entry in report.reasons.entries) {
      buffer.writeln('| match: ${entry.key} | ${entry.value} |');
    }
    buffer
      ..writeln('| rejected (needs review) | ${report.rejected.length} |')
      ..writeln('| unmatched | ${report.unmatched.length} |')
      ..writeln('| unmapped source chapters | ${report.unmappedChapters.length} |')
      ..writeln();

    if (report.rejected.isNotEmpty) {
      buffer
        ..writeln('<details><summary>Rejected pairs (top 20)</summary>')
        ..writeln();
      for (final r in report.rejected.take(20)) {
        buffer
          ..writeln('- `${r['adhkarId']}` — ${r['reason']} (${r['score']})')
          ..writeln('  - app: ${r['appText']}')
          ..writeln('  - src: ${r['bestCandidateText']}');
      }
      buffer
        ..writeln()
        ..writeln('</details>')
        ..writeln();
    }

    final json = File('tool/azkar_audio/reports/${report.readerId}.json');
    await json.parent.create(recursive: true);
    await json.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'readerId': report.readerId,
        'sourceRecords': report.sourceRecords,
        'mappedIndividual': report.singles,
        'categoryRecordings': report.categories,
        'reasons': report.reasons,
        'rejected': report.rejected,
        'unmatched': report.unmatched,
        'unmappedChapters': report.unmappedChapters,
      }),
    );
  }

  final out = File('docs/reports/adhkar-audio-mapping.md');
  await out.parent.create(recursive: true);
  await out.writeAsString(buffer.toString());
  stdout.writeln('→ ${out.path}');
}

String _clip(String raw) {
  final flat = raw.replaceAll('\n', ' ').trim();
  return flat.length <= 90 ? flat : '${flat.substring(0, 90)}…';
}
