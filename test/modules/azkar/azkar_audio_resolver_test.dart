import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_source.dart';
import 'package:quran/modules/azkar/domain/services/azkar_audio_resolver.dart';

MAzkarReader _reader(String id) => MAzkarReader(
  id: id,
  nameAr: id,
  nameEn: id,
  sourceName: 'test',
  sourceUrl: 'https://example.test',
  license: '',
  licenseStatus: EAzkarLicenseStatus.unknown,
  attribution: '',
  verified: true,
  mappedAdhkar: 1,
  categoryRecordings: 0,
  estimatedBytes: 1000,
);

MAzkarAudio _audio(String readerId) => MAzkarAudio(
  id: '$readerId:morning_1',
  readerId: readerId,
  type: EAzkarAudioType.singleAdhkar,
  adhkarId: 'morning_1',
  categoryIds: const <String>['morning'],
  remoteUrl: 'https://cdn.test/$readerId.mp3',
  matchingConfidence: EAzkarAudioMatch.exact,
);

void main() {
  const resolver = AzkarAudioResolver();

  final readers = <MAzkarReader>[
    _reader('alpha'),
    _reader('beta'),
    _reader('gamma'),
  ];

  EAzkarAudioSource run({
    String? preferred,
    Set<String> has = const <String>{'alpha', 'beta', 'gamma'},
    Set<String> downloaded = const <String>{},
    bool online = true,
    List<MAzkarReader>? readerList,
  }) {
    return resolver.resolve(
      preferredReaderId: preferred,
      readers: readerList ?? readers,
      lookup: (readerId) => has.contains(readerId) ? _audio(readerId) : null,
      isDownloaded: (audio) => downloaded.contains(audio.readerId),
      localPathOf: (audio) => '/local/${audio.readerId}.mp3',
      isOnline: online,
    );
  }

  group('the fallback ladder, in order', () {
    test('1 — preferred reader, downloaded', () {
      final result = run(preferred: 'beta', downloaded: {'alpha', 'beta'});
      expect(result.stage, EAzkarResolutionStage.preferredLocal);
      expect(result.reader?.id, 'beta');
      expect(result.uri, '/local/beta.mp3');
      expect(result.isLocal, isTrue);
      expect(result.isFallbackReader, isFalse);
    });

    test('2 — preferred reader, streamed', () {
      final result = run(preferred: 'beta');
      expect(result.stage, EAzkarResolutionStage.preferredRemote);
      expect(result.reader?.id, 'beta');
      expect(result.uri, 'https://cdn.test/beta.mp3');
      expect(result.isFallbackReader, isFalse);
    });

    test('the chosen voice outranks a downloaded substitute while online', () {
      // beta is preferred but not downloaded; gamma is. Online, the user still
      // gets the sheikh they asked for — swapping in a different voice merely
      // to avoid a stream would be the wrong trade.
      final result = run(preferred: 'beta', downloaded: {'gamma'});
      expect(result.stage, EAzkarResolutionStage.preferredRemote);
      expect(result.reader?.id, 'beta');
      expect(result.isFallbackReader, isFalse);
    });

    test('3 — another reader, downloaded, when the preferred one has nothing', () {
      final result = run(
        preferred: 'beta',
        has: {'alpha', 'gamma'},
        downloaded: {'gamma'},
      );
      expect(result.stage, EAzkarResolutionStage.fallbackLocal);
      expect(result.reader?.id, 'gamma');
      expect(result.isFallbackReader, isTrue);
      expect(result.uri, '/local/gamma.mp3');
    });

    test('3 — a downloaded substitute outranks streaming another one', () {
      // Neither rung is the preferred reader, so the one that needs no network
      // wins.
      final result = run(
        preferred: 'beta',
        has: {'alpha', 'gamma'},
        downloaded: {'gamma'},
      );
      expect(result.reader?.id, 'gamma');
      expect(result.isLocal, isTrue);
    });

    test('4 — another reader, streamed', () {
      final result = run(preferred: 'beta', has: {'gamma'});
      expect(result.stage, EAzkarResolutionStage.fallbackRemote);
      expect(result.reader?.id, 'gamma');
      expect(result.isFallbackReader, isTrue);
    });

    test('5 — nothing anywhere', () {
      final result = run(preferred: 'beta', has: const <String>{});
      expect(result.stage, EAzkarResolutionStage.none);
      expect(result.isPlayable, isFalse);
    });
  });

  group('offline', () {
    test('plays a downloaded file', () {
      final result = run(
        preferred: 'beta',
        downloaded: {'beta'},
        online: false,
      );
      expect(result.stage, EAzkarResolutionStage.preferredLocal);
      expect(result.uri, '/local/beta.mp3');
    });

    test('falls back to another downloaded reader', () {
      final result = run(
        preferred: 'beta',
        downloaded: {'gamma'},
        online: false,
      );
      expect(result.stage, EAzkarResolutionStage.fallbackLocal);
      expect(result.reader?.id, 'gamma');
    });

    test('says so plainly rather than pretending there is no audio', () {
      final result = run(preferred: 'beta', online: false);
      expect(result.stage, EAzkarResolutionStage.offlineUnavailable);
      expect(result.isPlayable, isFalse);
      // It still names what exists, so the UI can offer to download it.
      expect(result.audio, isNotNull);
    });

    test('reports none when nothing exists, offline or not', () {
      final result = run(
        preferred: 'beta',
        has: const <String>{},
        online: false,
      );
      expect(result.stage, EAzkarResolutionStage.none);
    });
  });

  group('determinism', () {
    test('with no preference, falls back in manifest order', () {
      final first = run(has: {'beta', 'gamma'});
      final second = run(has: {'beta', 'gamma'});
      expect(first.reader?.id, 'beta');
      expect(second.reader?.id, first.reader?.id);
      expect(first.stage, EAzkarResolutionStage.fallbackRemote);
    });

    test('an unknown preferred reader id degrades to the ladder', () {
      final result = run(preferred: 'nobody');
      expect(result.stage, EAzkarResolutionStage.fallbackRemote);
      expect(result.reader?.id, 'alpha');
    });

    test('an empty catalogue resolves to none', () {
      final result = run(readerList: const <MAzkarReader>[]);
      expect(result.stage, EAzkarResolutionStage.none);
    });
  });
}
