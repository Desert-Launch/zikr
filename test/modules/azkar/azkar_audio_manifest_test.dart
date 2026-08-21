import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_catalog.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

/// Two kinds of check live here:
///
///  * the parser's behaviour on hand-written JSON, and
///  * the **shipped** manifest under `assets/data/azkar_audio/`, read straight
///    off disk. That second group is the regression guard: it fails the build
///    if a regenerated manifest ever points at a dhikr that does not exist, at
///    a plain-http URL, or at an entry whose provenance was never established.
void main() {
  group('MAzkarAudioManifest parsing', () {
    test('refuses a manifest newer than this build understands', () {
      final manifest = MAzkarAudioManifest.fromJson(<String, dynamic>{
        'version': MAzkarAudioManifest.supportedVersion + 1,
        'readers': <dynamic>[],
      });
      expect(manifest.isSupported, isFalse);
    });

    test('hides a reader that is not verified or has no audio', () {
      final manifest = MAzkarAudioManifest.fromJson(<String, dynamic>{
        'version': 1,
        'readers': <dynamic>[
          <String, dynamic>{
            'id': 'good',
            'verified': true,
            'mappedAdhkar': 5,
            'categoryRecordings': 0,
          },
          <String, dynamic>{
            'id': 'unverified',
            'verified': false,
            'mappedAdhkar': 5,
            'categoryRecordings': 0,
          },
          <String, dynamic>{
            'id': 'empty',
            'verified': true,
            'mappedAdhkar': 0,
            'categoryRecordings': 0,
          },
        ],
      });
      expect(manifest.readers, hasLength(3));
      expect(manifest.usable.map((r) => r.id), <String>['good']);
    });
  });

  group('MAzkarReaderAudioIndex', () {
    test('drops an entry whose provenance was never established', () {
      final index = MAzkarReaderAudioIndex.fromJson(<String, dynamic>{
        'readerId': 'r',
        'audio': <dynamic>[
          <String, dynamic>{
            'id': 'r:a',
            'audioType': 'single_adhkar',
            'adhkarId': 'morning_1',
            'categoryIds': <String>['morning'],
            'remoteUrl': 'https://cdn.test/a.mp3',
            'matchingConfidence': 'exact',
          },
          <String, dynamic>{
            'id': 'r:b',
            'audioType': 'single_adhkar',
            'adhkarId': 'morning_2',
            'categoryIds': <String>['morning'],
            'remoteUrl': 'https://cdn.test/b.mp3',
            'matchingConfidence': 'unknown',
          },
          <String, dynamic>{
            'id': 'r:c',
            'audioType': 'single_adhkar',
            'adhkarId': 'morning_3',
            'categoryIds': <String>['morning'],
            'remoteUrl': '',
            'matchingConfidence': 'exact',
          },
        ],
      });
      expect(index.entries.map((e) => e.id), <String>['r:a']);
      expect(index.forAdhkar('morning_2'), isNull);
    });

    test('lists a combined recording under every sitting it covers', () {
      final index = MAzkarReaderAudioIndex.fromJson(<String, dynamic>{
        'readerId': 'r',
        'audio': <dynamic>[
          <String, dynamic>{
            'id': 'r:cat:1',
            'audioType': 'category_recording',
            'categoryIds': <String>['morning', 'evening'],
            'titleAr': 'أذكار الصباح والمساء',
            'remoteUrl': 'https://cdn.test/both.mp3',
            'matchingConfidence': 'manual',
          },
        ],
      });
      expect(index.forCategory('morning'), hasLength(1));
      expect(index.forCategory('evening'), hasLength(1));
      // One file, two entry points — not two downloads.
      expect(
        index.forCategory('morning').single.id,
        index.forCategory('evening').single.id,
      );
      expect(index.categoryCount, 1);
      expect(index.singleCount, 0);
    });

    test('derives a filesystem-safe, stable stem per entry', () {
      final single = MAzkarAudio.fromJson(<String, dynamic>{
        'id': 'r:other_12_345',
        'audioType': 'single_adhkar',
        'adhkarId': 'other_12_345',
        'categoryIds': <String>['other_12'],
        'remoteUrl': 'https://cdn.test/x.mp3',
        'matchingConfidence': 'exact',
      }, 'r');
      expect(single.fileStem, 'other_12_345');

      final category = MAzkarAudio.fromJson(<String, dynamic>{
        'id': 'r:cat:item id/with slashes',
        'audioType': 'category_recording',
        'categoryIds': <String>['morning'],
        'remoteUrl': 'https://cdn.test/y.mp3',
        'matchingConfidence': 'manual',
      }, 'r');
      expect(category.fileStem, startsWith('cat_'));
      expect(category.fileStem, isNot(contains('/')));
      expect(category.fileStem, isNot(contains(' ')));
    });
  });

  group('the shipped manifest', () {
    late MAzkarAudioManifest manifest;
    late Map<String, MAzkarReaderAudioIndex> indexes;
    late Set<String> adhkarIds;
    late Set<String> categoryIds;

    setUpAll(() {
      manifest = MAzkarAudioManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
                File('assets/data/azkar_audio/readers.json').readAsStringSync(),
              )
              as Map,
        ),
      );
      indexes = <String, MAzkarReaderAudioIndex>{
        for (final reader in manifest.readers)
          reader.id: MAzkarReaderAudioIndex.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(
                    File(
                      'assets/data/azkar_audio/mappings/${reader.id}.json',
                    ).readAsStringSync(),
                  )
                  as Map,
            ),
          ),
      };

      // Rebuild the app's dhikr ids exactly the way the app composes them.
      adhkarIds = <String>{};
      categoryIds = <String>{};
      const dir = 'assets/data/azkar';
      final catalog =
          (jsonDecode(
                    File('$dir/azkar_catigories.json').readAsStringSync(),
                  )
                  as List<dynamic>)
              .map(
                (e) => MAzkarCatalog.fromJson(Map<String, dynamic>.from(e as Map)),
              );
      for (final row in catalog.where((e) => !e.isOther)) {
        categoryIds.add(row.slug);
        for (final e
            in jsonDecode(File('$dir/${row.filename}').readAsStringSync())
                as List<dynamic>) {
          final map = Map<String, dynamic>.from(e as Map);
          adhkarIds.add(MAzkarItem.composeId(row.slug, map['id']));
        }
      }
      final other = Map<String, dynamic>.from(
        jsonDecode(
              File('$dir/${MAzkarCatalog.otherFile}').readAsStringSync(),
            )
            as Map,
      );
      var index = 0;
      for (final entry in other.entries) {
        final categoryId = 'other_$index';
        categoryIds.add(categoryId);
        for (final e in entry.value as List<dynamic>) {
          final map = Map<String, dynamic>.from(e as Map);
          adhkarIds.add(MAzkarItem.composeId(categoryId, map['id']));
        }
        index++;
      }
    });

    test('is a version this build supports', () {
      expect(manifest.isSupported, isTrue);
      expect(manifest.readers, isNotEmpty);
    });

    test('every reader has a mapping file and is verified', () {
      for (final reader in manifest.readers) {
        expect(
          File('assets/data/azkar_audio/mappings/${reader.id}.json').existsSync(),
          isTrue,
          reason: '${reader.id} has no mapping file',
        );
        expect(reader.verified, isTrue, reason: '${reader.id} is unverified');
        expect(reader.hasAnyAudio, isTrue, reason: '${reader.id} has no audio');
        expect(reader.attribution, isNotEmpty);
        expect(reader.sourceUrl, startsWith('https://'));
      }
    });

    test('every individual recording points at a dhikr that exists', () {
      for (final entry in indexes.entries) {
        for (final audio in entry.value.entries) {
          if (audio.isCategoryRecording) continue;
          expect(
            adhkarIds,
            contains(audio.adhkarId),
            reason: '${entry.key}: "${audio.adhkarId}" is not an app dhikr',
          );
        }
      }
    });

    test('every category reference points at a category that exists', () {
      for (final entry in indexes.entries) {
        for (final audio in entry.value.entries) {
          expect(audio.categoryIds, isNotEmpty, reason: audio.id);
          for (final category in audio.categoryIds) {
            expect(
              categoryIds,
              contains(category),
              reason: '${entry.key}: "$category" is not an app category',
            );
          }
        }
      }
    });

    test('every URL is https — plain http is blocked on both platforms', () {
      for (final entry in indexes.entries) {
        for (final audio in entry.value.entries) {
          expect(
            audio.remoteUrl,
            startsWith('https://'),
            reason: '${entry.key}: ${audio.id}',
          );
        }
      }
    });

    test('no entry ships with unestablished provenance', () {
      for (final entry in indexes.entries) {
        for (final audio in entry.value.entries) {
          expect(
            audio.matchingConfidence,
            isNot(EAzkarAudioMatch.unknown),
            reason: '${entry.key}: ${audio.id}',
          );
        }
      }
    });

    test('entry ids are unique within a reader', () {
      for (final entry in indexes.entries) {
        final ids = entry.value.entries.map((a) => a.id).toList();
        expect(ids.toSet(), hasLength(ids.length), reason: entry.key);
      }
    });

    test('the advertised counts match the mapping files exactly', () {
      // Guards §34: a reader must never claim adhkar it does not have.
      for (final reader in manifest.readers) {
        final index = indexes[reader.id];
        expect(reader.mappedAdhkar, index?.singleCount, reason: reader.id);
        expect(
          reader.categoryRecordings,
          index?.categoryCount,
          reason: reader.id,
        );
      }
    });

    test('a category recording is never attached to a single dhikr', () {
      for (final entry in indexes.entries) {
        for (final audio in entry.value.entries) {
          if (!audio.isCategoryRecording) continue;
          expect(
            audio.adhkarId,
            isNull,
            reason:
                '${entry.key}: whole-sitting recording ${audio.id} must not '
                'claim to be one dhikr',
          );
        }
      }
    });
  });
}
