import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/car/domain/entities/e_car_query_match.dart';
import 'package:quran/modules/car/domain/usecases/uc_match_car_query.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

/// Runs against the bundled catalogues, so a renamed surah or a new reciter
/// whose name collides with a surah's shows up here.
void main() {
  late List<MSurah> surahs;
  late List<MReciter> reciters;
  const stations = [
    MRadioStation(
      id: 'national_eg_cairo',
      name: 'إذاعة القرآن الكريم من القاهرة',
      nameEn: 'Holy Quran Radio — Cairo',
      url: 'https://example.com/cairo',
      isNational: true,
    ),
    MRadioStation(
      id: 'national_qa_doha',
      name: 'إذاعة القرآن الكريم - الدوحة',
      nameEn: 'Holy Quran Radio — Doha',
      url: 'https://example.com/doha',
      isNational: true,
    ),
  ];
  const match = UCMatchCarQuery();

  setUpAll(() {
    List<Map<String, dynamic>> load(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as List)
            .cast<Map<String, dynamic>>();
    surahs = load('assets/data/surahs.json').map(MSurah.fromJson).toList();
    reciters = load(
      'assets/data/reciters.json',
    ).map(MReciter.fromJson).toList();
  });

  ECarQueryMatch? best(String query) {
    final all = match(
      query,
      surahs: surahs,
      reciters: reciters,
      stations: stations,
    );
    return all.isEmpty ? null : all.first;
  }

  group('surah by name', () {
    test('Arabic, with «سورة» and diacritics', () {
      expect(best('سورة الكَهْف'), const ECarSurahMatch(surah: 18));
      expect(best('شغل سورة يس'), const ECarSurahMatch(surah: 36));
    });

    test('Arabic without the article', () {
      expect(best('كهف'), const ECarSurahMatch(surah: 18));
    });

    test('«آل عمران» with or without «آل»', () {
      expect(best('سورة آل عمران'), const ECarSurahMatch(surah: 3));
      expect(best('عمران'), const ECarSurahMatch(surah: 3));
    });

    test('Latin transliteration, article and trailing h folded', () {
      expect(best('play Surah Al-Kahf'), const ECarSurahMatch(surah: 18));
      expect(best('al baqara'), const ECarSurahMatch(surah: 2));
      expect(best('surah al-fatihah'), const ECarSurahMatch(surah: 1));
    });

    test('one-letter slip in a long Latin name', () {
      expect(best('surah rehman'), const ECarSurahMatch(surah: 55));
    });

    test('English meaning', () {
      expect(best('play the cave'), const ECarSurahMatch(surah: 18));
    });

    test('by number, Western or Arabic-Indic digits', () {
      expect(best('surah 18'), const ECarSurahMatch(surah: 18));
      expect(best('سورة ١٨'), const ECarSurahMatch(surah: 18));
    });
  });

  group('surah with reciter', () {
    test('Arabic «لل» joined to the reciter', () {
      expect(
        best('شغل سورة الكهف للعفاسي'),
        const ECarSurahMatch(surah: 18, reciterId: 'alafasy'),
      );
    });

    test('English "by"', () {
      expect(
        best('play al baqara by mishary'),
        const ECarSurahMatch(surah: 2, reciterId: 'alafasy'),
      );
    });

    test('a reciter name holding a surah name is still the reciter', () {
      // «عبد الرحمن» contains «الرحمن»; here it is the reciter's.
      expect(
        best('سورة الكهف لعبد الرحمن السديس'),
        const ECarSurahMatch(surah: 18, reciterId: 'sudais'),
      );
      // …but straight after «سورة» it is the surah.
      expect(
        best('سورة الرحمن للسديس'),
        const ECarSurahMatch(surah: 55, reciterId: 'sudais'),
      );
      expect(
        best('surah ar-rahman by sudais'),
        const ECarSurahMatch(surah: 55, reciterId: 'sudais'),
      );
    });

    test('a style word picks the edition', () {
      expect(
        best('سورة الملك الحصري مجود'),
        const ECarSurahMatch(surah: 67, reciterId: 'husary_mujawwad'),
      );
    });
  });

  group('no reciter where only a surah was said', () {
    test('«الرحمن» alone is the surah', () {
      expect(best('شغل الرحمن'), const ECarSurahMatch(surah: 55));
    });
  });

  group('reciter alone', () {
    test('Arabic and English', () {
      expect(best('العفاسي'), const ECarReciterMatch('alafasy'));
      expect(best('play maher'), const ECarReciterMatch('maher'));
    });
  });

  group('radio', () {
    test('by city, Arabic and English', () {
      expect(
        best('إذاعة القرآن الكريم من القاهرة'),
        const ECarStationMatch('national_eg_cairo'),
      );
      expect(
        best('quran radio doha'),
        const ECarStationMatch('national_qa_doha'),
      );
    });

    test('radio with no station named → the first station', () {
      expect(best('راديو القرآن'), const ECarStationMatch('national_eg_cairo'));
    });
  });

  group('nothing to match', () {
    test('empty and filler-only queries', () {
      expect(best(''), isNull);
      expect(best('play'), isNull);
      expect(best('شغل القرآن الكريم'), isNull);
    });
  });
}
