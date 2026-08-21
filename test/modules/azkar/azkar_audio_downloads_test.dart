import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_azkar_audio_files.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar_audio.dart';
import 'package:quran/modules/azkar/data/datasources/remote/ds_azkar_audio_downloader.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_download.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_manifest.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/data/repos/r_impl_azkar_audio.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_audio_download.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_audio_pref.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

// ---------------------------------------------------------------------------
// Fakes — every collaborator that would touch the network, the app bundle or
// the real documents directory.
// ---------------------------------------------------------------------------

class _FakeManifest extends DSLocalAzkarAudio {
  _FakeManifest(this.entriesByReader);

  final Map<String, List<MAzkarAudio>> entriesByReader;

  @override
  Future<List<MAzkarReader>> readers() async => entriesByReader.keys
      .map(
        (id) => MAzkarReader(
          id: id,
          nameAr: id,
          nameEn: id,
          sourceName: 'test',
          sourceUrl: 'https://example.test',
          license: '',
          licenseStatus: EAzkarLicenseStatus.unknown,
          attribution: '',
          verified: true,
          mappedAdhkar: entriesByReader[id]?.length ?? 0,
          categoryRecordings: 0,
          estimatedBytes: 0,
        ),
      )
      .toList(growable: false);

  @override
  Future<MAzkarReaderAudioIndex> indexFor(String readerId) async =>
      MAzkarReaderAudioIndex(
        readerId: readerId,
        entries: entriesByReader[readerId] ?? const <MAzkarAudio>[],
      );

  @override
  Future<List<MAzkarAudio>> allFor(String readerId) async =>
      entriesByReader[readerId] ?? const <MAzkarAudio>[];
}

class _TempFiles extends DSAzkarAudioFiles {
  _TempFiles(this.root);
  final Directory root;

  @override
  Future<String> baseDir() async {
    if (!root.existsSync()) root.createSync(recursive: true);
    return root.path;
  }
}

/// Writes deterministic bytes instead of making a request. [failFor] makes a
/// given audio id throw, and [attempts] records every call so a test can prove
/// a file was fetched once, not twice.
class _FakeDownloader extends DSAzkarAudioDownloader {
  _FakeDownloader({this.failFor = const <String>{}});

  final Set<String> failFor;

  /// Every simulated file is this size, so byte assertions are exact.
  static const int bytes = 2048;
  final List<String> attempts = <String>[];
  final List<int> resumedFrom = <int>[];

  @override
  Future<AzkarDownloadResult> download({
    required String taskId,
    required String url,
    required String savePath,
    required String partPath,
    int existingBytes = 0,
    void Function(int received, int total)? onProgress,
  }) async {
    attempts.add(taskId);
    resumedFrom.add(existingBytes);
    if (failFor.contains(taskId)) {
      throw const SocketException('simulated network failure');
    }
    final file = File(savePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List<int>.filled(bytes, 7));
    onProgress?.call(bytes, bytes);
    return AzkarDownloadResult(
      bytes: bytes,
      resumed: existingBytes > 0,
      cancelled: false,
    );
  }
}

class _FakeAzkar extends DSLocalAzkar {
  @override
  Future<List<MAzkarCategory>> allCategories() async => <MAzkarCategory>[
    const MAzkarCategory(
      id: 'morning',
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning',
      items: <MAzkarItem>[],
    ),
    const MAzkarCategory(
      id: 'evening',
      nameAr: 'أذكار المساء',
      nameEn: 'Evening',
      items: <MAzkarItem>[],
    ),
  ];

  @override
  Future<List<MAzkarCategory>> otherCategories() async =>
      const <MAzkarCategory>[];
}

MAzkarAudio _single(String readerId, String adhkarId, String category) =>
    MAzkarAudio(
      id: '$readerId:$adhkarId',
      readerId: readerId,
      type: EAzkarAudioType.singleAdhkar,
      adhkarId: adhkarId,
      categoryIds: <String>[category],
      remoteUrl: 'https://cdn.test/$readerId/$adhkarId.mp3',
      fileSize: 2048,
      matchingConfidence: EAzkarAudioMatch.exact,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late BoxAzkarAudioDownload downloads;
  late BoxAzkarAudioPref prefs;
  late _TempFiles files;
  late _FakeManifest manifest;

  final entries = <String, List<MAzkarAudio>>{
    'alpha': <MAzkarAudio>[
      _single('alpha', 'morning_1', 'morning'),
      _single('alpha', 'morning_2', 'morning'),
      _single('alpha', 'evening_1', 'evening'),
    ],
  };

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('azkar_audio_test');
    Hive.init('${temp.path}/hive');
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(MAzkarAudioDownloadAdapter());
    }
    await Hive.openBox<MAzkarAudioDownload>(BoxAzkarAudioDownload.boxName_);
    await Hive.openBox<String>(BoxAzkarAudioPref.boxName_);
    downloads = BoxAzkarAudioDownload();
    prefs = BoxAzkarAudioPref();
    files = _TempFiles(Directory('${temp.path}/audio'));
    manifest = _FakeManifest(entries);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  RImplAzkarAudio buildRepo(DSAzkarAudioDownloader downloader) =>
      RImplAzkarAudio(
        manifest: manifest,
        files: files,
        downloader: downloader,
        downloads: downloads,
        prefs: prefs,
        azkar: _FakeAzkar(),
      );

  group('pack download', () {
    test('fetches every file and records it', () async {
      final downloader = _FakeDownloader();
      final repo = buildRepo(downloader);

      final progress = await repo.download('alpha').toList();

      expect(downloader.attempts, hasLength(3));
      expect(progress.last.completed, 3);
      expect(progress.last.failed, 0);
      expect(progress.last.isDone, isTrue);

      final stats = (await repo.readerStats('alpha')).getOrElse(
        () => throw StateError('stats failed'),
      );
      expect(stats.downloaded, 3);
      expect(stats.total, 3);
      expect(stats.isComplete, isTrue);
    });

    test('is idempotent — a second run re-fetches nothing', () async {
      final downloader = _FakeDownloader();
      final repo = buildRepo(downloader);

      await repo.download('alpha').toList();
      expect(downloader.attempts, hasLength(3));

      await repo.download('alpha').toList();
      expect(
        downloader.attempts,
        hasLength(3),
        reason: 'files already on disk must be skipped, not downloaded twice',
      );
    });

    test('a duplicate request joins the run in flight', () async {
      final downloader = _FakeDownloader();
      final repo = buildRepo(downloader);

      final first = repo.download('alpha');
      final second = repo.download('alpha');
      await Future.wait([first.toList(), second.toList()]);

      expect(
        downloader.attempts,
        hasLength(3),
        reason: 'the second caller must share the first run, not start another',
      );
    });

    test('downloads a single category without the rest of the pack', () async {
      final downloader = _FakeDownloader();
      final repo = buildRepo(downloader);

      final progress = await repo
          .download('alpha', categoryId: 'evening')
          .toList();

      expect(downloader.attempts, <String>['alpha:evening_1']);
      expect(progress.last.total, 1);
      expect(progress.last.completed, 1);
    });

    test('reports a failure without abandoning the rest', () async {
      final downloader = _FakeDownloader(failFor: {'alpha:morning_2'});
      final repo = buildRepo(downloader);

      final progress = await repo.download('alpha').toList();

      expect(progress.last.completed, 2);
      expect(progress.last.failed, 1);
      expect(downloads.byId('alpha:morning_2')?.isFailed, isTrue);
      expect(downloads.byId('alpha:morning_1')?.isDownloaded, isTrue);
    });

    test('a retry after a failure fetches only the file that failed', () async {
      final failing = _FakeDownloader(failFor: {'alpha:morning_2'});
      await buildRepo(failing).download('alpha').toList();

      final retry = _FakeDownloader();
      await buildRepo(retry).download('alpha').toList();

      expect(retry.attempts, <String>['alpha:morning_2']);
      expect(downloads.byId('alpha:morning_2')?.isDownloaded, isTrue);
    });
  });

  group('persistence and reconciliation', () {
    test('download state survives a new repo instance', () async {
      await buildRepo(_FakeDownloader()).download('alpha').toList();

      // A fresh repo stands in for a restarted app: same Hive box, same disk.
      final restarted = buildRepo(_FakeDownloader());
      final stats = (await restarted.readerStats('alpha')).getOrElse(
        () => throw StateError('stats failed'),
      );
      expect(stats.downloaded, 3);
    });

    test('repairs a record whose file the OS reclaimed', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha').toList();

      final victim = entries['alpha']!.first;
      await File(await files.pathFor(victim)).delete();

      final repaired = (await repo.reconcile()).getOrElse(() => -1);
      expect(repaired, 1);
      expect(downloads.byId(victim.id), isNull);

      final stats = (await repo.readerStats('alpha')).getOrElse(
        () => throw StateError('stats failed'),
      );
      expect(stats.downloaded, 2);
    });

    test('promotes a finished file whose record never got written', () async {
      final audio = entries['alpha']!.first;
      // The rename is the last step of a transfer, so a complete file with a
      // stale record means the process died in between — the bytes are good.
      final path = await files.pathFor(audio);
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes(List<int>.filled(1024, 1));
      await downloads.save(
        MAzkarAudioDownload(
          audioId: audio.id,
          readerId: audio.readerId,
          remoteUrl: audio.remoteUrl,
          localPath: path,
          status: MAzkarAudioDownload.statusDownloading,
        ),
      );

      final repo = buildRepo(_FakeDownloader());
      expect((await repo.reconcile()).getOrElse(() => -1), 1);
      expect(downloads.byId(audio.id)?.isDownloaded, isTrue);
      expect(downloads.byId(audio.id)?.bytesDownloaded, 1024);
    });

    test('demotes a killed transfer to pending so it can resume', () async {
      final audio = entries['alpha']!.first;
      await downloads.save(
        MAzkarAudioDownload(
          audioId: audio.id,
          readerId: audio.readerId,
          remoteUrl: audio.remoteUrl,
          localPath: await files.pathFor(audio),
          bytesDownloaded: 512,
          status: MAzkarAudioDownload.statusDownloading,
        ),
      );

      final repo = buildRepo(_FakeDownloader());
      expect((await repo.reconcile()).getOrElse(() => -1), 1);
      expect(
        downloads.byId(audio.id)?.status,
        MAzkarAudioDownload.statusPending,
      );
    });

    test('resumes from the bytes already in the part file', () async {
      final audio = entries['alpha']!.first;
      final part = await files.partPathFor(audio);
      await File(part).parent.create(recursive: true);
      await File(part).writeAsBytes(List<int>.filled(900, 3));

      final downloader = _FakeDownloader();
      await buildRepo(downloader).download('alpha').toList();

      final index = downloader.attempts.indexOf(audio.id);
      expect(index, isNonNegative);
      expect(downloader.resumedFrom[index], 900);
    });
  });

  group('deletion and storage', () {
    test('deleting a reader clears its files and its records', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha').toList();
      expect((await repo.storageUsage()).getOrElse(
        () => throw StateError('usage failed'),
      ).totalBytes, greaterThan(0));

      await repo.deleteReader('alpha');

      expect(downloads.forReader('alpha'), isEmpty);
      expect(await files.readerDirExists('alpha'), isFalse);
      final stats = (await repo.readerStats('alpha')).getOrElse(
        () => throw StateError('stats failed'),
      );
      expect(stats.downloaded, 0);
    });

    test('deleting one category leaves the others alone', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha').toList();

      await repo.deleteCategory('alpha', 'evening');

      expect(downloads.byId('alpha:evening_1'), isNull);
      expect(downloads.byId('alpha:morning_1')?.isDownloaded, isTrue);
    });

    test('deleting everything empties the store', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha').toList();

      await repo.deleteAll();

      expect(downloads.all(), isEmpty);
      final usage = (await repo.storageUsage()).getOrElse(
        () => throw StateError('usage failed'),
      );
      expect(usage.isEmpty, isTrue);
    });

    test('reports usage per reader', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha').toList();

      final usage = (await repo.storageUsage()).getOrElse(
        () => throw StateError('usage failed'),
      );
      expect(usage.perReader['alpha'], 3 * 2048);
      expect(usage.totalBytes, 3 * 2048);
    });
  });

  group('category breakdown', () {
    test('groups a pack by category with real counts', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.download('alpha', categoryId: 'evening').toList();

      final breakdown = (await repo.categoryBreakdown('alpha')).getOrElse(
        () => throw StateError('breakdown failed'),
      );
      final morning = breakdown.firstWhere((c) => c.categoryId == 'morning');
      final evening = breakdown.firstWhere((c) => c.categoryId == 'evening');

      expect(morning.total, 2);
      expect(morning.downloaded, 0);
      expect(evening.total, 1);
      expect(evening.downloaded, 1);
      expect(evening.isComplete, isTrue);
      expect(evening.nameAr, 'أذكار المساء');
    });
  });

  group('preferred reader', () {
    test('round-trips through storage', () async {
      final repo = buildRepo(_FakeDownloader());
      expect(repo.preferredReaderId, isNull);

      await repo.setPreferredReader('alpha');
      expect(repo.preferredReaderId, 'alpha');

      // A new instance reads the same persisted value.
      expect(buildRepo(_FakeDownloader()).preferredReaderId, 'alpha');

      await repo.setPreferredReader(null);
      expect(repo.preferredReaderId, isNull);
    });
  });

  group('resolution against real download state', () {
    test('prefers the downloaded local file over the remote URL', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.setPreferredReader('alpha');
      await repo.download('alpha').toList();

      final source = (await repo.resolveAdhkar('morning_1')).getOrElse(
        () => throw StateError('resolve failed'),
      );
      expect(source.isLocal, isTrue);
      expect(source.uri, endsWith('morning_1.mp3'));
      expect(source.reader?.id, 'alpha');
    });

    test('streams when nothing is downloaded', () async {
      final repo = buildRepo(_FakeDownloader());
      await repo.setPreferredReader('alpha');

      final source = (await repo.resolveAdhkar('morning_1')).getOrElse(
        () => throw StateError('resolve failed'),
      );
      expect(source.isLocal, isFalse);
      expect(source.uri, 'https://cdn.test/alpha/morning_1.mp3');
    });

    test('reports nothing for a dhikr no reader has', () async {
      final repo = buildRepo(_FakeDownloader());
      final source = (await repo.resolveAdhkar('sleeping_9')).getOrElse(
        () => throw StateError('resolve failed'),
      );
      expect(source.isPlayable, isFalse);
    });
  });
}
