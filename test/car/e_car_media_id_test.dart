import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/car/domain/entities/e_car_media_id.dart';

void main() {
  group('ECarMediaId', () {
    test('every id parses back to itself', () {
      const ids = <ECarMediaId>[
        ECarReciters(),
        ECarReciterSurahs('alafasy'),
        ECarSurah(reciterId: 'husary_mujawwad', surah: 18),
        ECarDownloads(),
        ECarRadio(),
        ECarLiveRadio(),
        ECarStation('national_eg_cairo'),
        ECarStation('mp3q_12'),
      ];
      for (final id in ids) {
        expect(ECarMediaId.parse(id.value), id, reason: id.value);
      }
    });

    test('ids are distinct', () {
      final values = {
        const ECarReciters().value,
        const ECarDownloads().value,
        const ECarRadio().value,
        const ECarLiveRadio().value,
      };
      expect(values, hasLength(4));
    });

    test('station ids keep separators they may carry', () {
      expect(
        ECarMediaId.parse('station/a/b'),
        const ECarStation('a/b'),
      );
    });

    test('rejects ids it never handed out', () {
      for (final raw in [
        '',
        'root',
        'recent',
        'quran/',
        'quran/alafasy/0',
        'quran/alafasy/115',
        'quran/alafasy/abc',
        'quran/alafasy/18/extra',
        'station/',
        'unknown',
      ]) {
        expect(ECarMediaId.parse(raw), isNull, reason: raw);
      }
    });
  });
}
