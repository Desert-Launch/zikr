import 'dart:convert';
import 'dart:io';

import 'http_util.dart';
import 'sources.dart';

/// Resolves every [ArchiveRecording] declared in `sources.dart` against the
/// Internet Archive metadata API, so the manifest carries real byte sizes and
/// durations instead of guesses.
///
/// It also fails loudly when a declared filename is not in the item — a typo in
/// an Arabic filename is otherwise invisible until a user taps play.
///
///   dart run tool/azkar_audio/import_archive_reader.dart [readerId ...]
Future<void> main(List<String> args) async {
  final wanted = args.toSet();
  final readers = readerSources
      .where((r) => r.archiveItems.isNotEmpty)
      .where((r) => wanted.isEmpty || wanted.contains(r.id))
      .toList(growable: false);

  final itemIds = <String>{
    for (final r in readers)
      for (final a in r.archiveItems) a.itemId,
  };
  stdout.writeln(
    'Resolving ${itemIds.length} archive.org items for ${readers.length} readers',
  );

  final metadata = <String, Map<String, dynamic>>{};
  for (final id in itemIds) {
    try {
      metadata[id] = await HttpUtil.getJsonMap(
        'https://archive.org/metadata/$id',
      );
      stdout.writeln('  ✓ $id');
    } catch (e) {
      stdout.writeln('  ✗ $id — $e');
    }
  }

  final resolved = <String, dynamic>{};
  var missing = 0;
  for (final reader in readers) {
    final entries = <Map<String, dynamic>>[];
    for (final rec in reader.archiveItems) {
      final meta = metadata[rec.itemId];
      final files = (meta?['files'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Map<String, dynamic>.from(e as Map));
      final hit = files
          .where((f) => f['name'] == rec.fileName)
          .cast<Map<String, dynamic>?>()
          .firstWhere((f) => f != null, orElse: () => null);
      if (hit == null) {
        missing++;
        stdout.writeln(
          '  ! ${reader.id}: "${rec.fileName}" not found in ${rec.itemId}',
        );
        continue;
      }
      entries.add(<String, dynamic>{
        'itemId': rec.itemId,
        'fileName': rec.fileName,
        'titleAr': rec.titleAr,
        'categoryIds': rec.categoryIds,
        'url': rec.url,
        'sourceUrl': rec.itemUrl,
        'fileSize': int.tryParse('${hit['size']}') ?? 0,
        'duration': _seconds(hit['length']),
      });
    }
    resolved[reader.id] = entries;
  }

  final out = File('tool/azkar_audio/raw/archive_items.json');
  await out.parent.create(recursive: true);
  await out.writeAsString(
    const JsonEncoder.withIndent('  ').convert(resolved),
  );
  stdout.writeln('→ ${out.path}  (missing files: $missing)');
  HttpUtil.close();
  if (missing > 0) exitCode = 1;
}

/// archive.org reports durations either as seconds (`"1233.37"`) or as
/// `mm:ss` / `hh:mm:ss`, depending on how the item was derived.
int? _seconds(Object? raw) {
  if (raw == null) return null;
  final text = '$raw';
  final plain = double.tryParse(text);
  if (plain != null) return plain.round();
  final parts = text.split(':').map(int.tryParse).toList();
  if (parts.any((p) => p == null)) return null;
  var total = 0;
  for (final part in parts) {
    total = total * 60 + (part ?? 0);
  }
  return total;
}
