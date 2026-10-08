import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

void main() {
  group('MAzkarItem.fromJson closing flag', () {
    test('reads "closing": true', () {
      final item = MAzkarItem.fromJson({'id': 29, 'zekr': 'اكتمل', 'count': 1, 'closing': true}, 'morning');
      expect(item.isClosing, isTrue);
    });

    test('a file without the key reads as an ordinary zekr', () {
      final item = MAzkarItem.fromJson({'id': 1, 'zekr': 'سبحان الله', 'count': 3}, 'other_0');
      expect(item.isClosing, isFalse);
    });
  });

  // Guards the bundled data against a re-import that loses the flag or moves
  // the card: every daily list ends on exactly one closing card.
  test('every daily azkar file ends on exactly one closing card', () {
    final catalog = jsonDecode(File('assets/data/azkar/azkar_catigories.json').readAsStringSync()) as List<dynamic>;
    final files = catalog
        .map((e) => (e as Map<String, dynamic>)['filename'] as String)
        .where((f) => f != 'other_azkar.json');
    expect(files, isNotEmpty);
    for (final file in files) {
      final raw = jsonDecode(File('assets/data/azkar/$file').readAsStringSync()) as List<dynamic>;
      final items = raw.map((e) => MAzkarItem.fromJson(e as Map<String, dynamic>, file)).toList();
      expect(items.where((i) => i.isClosing).length, 1, reason: file);
      expect(items.last.isClosing, isTrue, reason: file);
    }
  });
}
