import 'dart:convert';
import 'dart:io';

import 'package:quran/modules/azkar/domain/services/azkar_source_text_cleaner.dart';


import 'http_util.dart';
import 'sources.dart';

/// Pulls the whole Hisn al-Muslim catalogue from hisnmuslim.com into
/// `tool/azkar_audio/raw/hisn_muslim.json`.
///
/// The site publishes an index (`husn_ar.json`) of 132 chapters, each with a
/// whole-chapter recording, plus a per-chapter file listing every dhikr with
/// its own MP3. That is the only source found that ships **one file per
/// dhikr**, which is why it is the reference reader.
///
///   dart run tool/azkar_audio/import_hisn_muslim.dart
Future<void> main(List<String> args) async {
  final reader = readerSources.firstWhere((r) => r.hisnMuslim);
  stdout.writeln('Importing ${reader.nameEn} from ${reader.sourceUrl}');

  const cleaner = AzkarSourceTextCleaner();
  const indexUrl = 'https://www.hisnmuslim.com/api/ar/husn_ar.json';
  final index = await HttpUtil.getJsonMap(indexUrl);
  final rows = (index.values.first as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
  stdout.writeln('  chapters: ${rows.length}');

  final categories = <Map<String, dynamic>>[];
  var entryCount = 0;
  for (final row in rows) {
    final id = (row['ID'] as num).toInt();
    final title = (row['TITLE'] as String? ?? '').trim();
    final body = await HttpUtil.getJsonMap(
      'https://www.hisnmuslim.com/api/ar/$id.json',
    );
    final items = (body.values.first as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => ((e['AUDIO'] as String?) ?? '').isNotEmpty)
        .map(
          (e) => <String, dynamic>{
            'id': (e['ID'] as num).toInt(),
            // The recitation is the dhikr alone — the book's `(( ))` wrapper,
            // repetition notes and bracketed evening variant are apparatus.
            'text': cleaner.clean(e['ARABIC_TEXT'] as String?),
            'rawText': (e['ARABIC_TEXT'] as String? ?? '').trim(),
            'repeat': (e['REPEAT'] as num?)?.toInt() ?? 1,
            'audio': _https(e['AUDIO'] as String),
          },
        )
        .toList(growable: false);
    entryCount += items.length;
    categories.add(<String, dynamic>{
      'id': id,
      'title': title,
      'audioUrl': _https(row['AUDIO_URL'] as String? ?? ''),
      'entries': items,
    });
    stdout.write('\r  fetched ${categories.length}/${rows.length} chapters');
  }
  stdout.writeln();

  final out = File('tool/azkar_audio/raw/hisn_muslim.json');
  await out.parent.create(recursive: true);
  await out.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'source': reader.sourceUrl,
      'readerId': reader.id,
      'licenseStatus': reader.licenseStatus.asJson,
      'categories': categories,
    }),
  );

  stdout.writeln('  individual adhkar with audio: $entryCount');
  stdout.writeln('  chapter recordings: ${categories.length}');
  stdout.writeln('→ ${out.path}');
  HttpUtil.close();
}

/// The API hands out `http://` links; the app only ever loads https (iOS ATS
/// and Android cleartext rules both block plain http by default). The host
/// serves the same paths over TLS.
String _https(String url) =>
    url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
