import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_progress.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';

/// The adapter as it was before `lastItemId` (field 3) existed, to write the
/// records users already have on their devices.
class _LegacyProgressAdapter extends TypeAdapter<MAzkarProgress> {
  @override
  final typeId = HiveTypeIds.azkarProgress;

  @override
  MAzkarProgress read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, MAzkarProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayKey)
      ..writeByte(1)
      ..write(obj.completedCounts)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }
}

void main() {
  late Directory tempDir;
  final progress = BoxAzkarProgress();

  // 12 azkar; the 10th is said 3 times, the rest once.
  final evening = MAzkarCategory(
    id: 'evening',
    nameAr: 'أذكار المساء',
    nameEn: 'Evening',
    items: [
      for (var i = 1; i <= 12; i++) MAzkarItem(id: 'evening_$i', textAr: 'zekr $i', repeat: i == 10 ? 3 : 1),
    ],
  );

  /// Says azkar 1–9 in full and the 10th once, then sits on the 10th.
  Future<void> stopMidwayThroughTenth() async {
    for (var i = 1; i <= 10; i++) {
      await progress.increment('evening', 'evening_$i');
    }
    await progress.setLastItem('evening', 'evening_10');
  }

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('azkar_progress_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(MAzkarProgressAdapter());
    await Hive.openBox<MAzkarProgress>(progress.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() => progress.box.clear());

  test('no session today → nothing to resume', () {
    expect(progress.resumeIndex(evening), isNull);
  });

  test('stopped on zekr 10 mid-count → resumes on it with its count', () async {
    await stopMidwayThroughTenth();

    expect(progress.resumeIndex(evening), 9);
    expect(progress.today('evening').completedCounts['evening_10'], 1);
  });

  test('the record survives reopening the box, as after an app kill', () async {
    await stopMidwayThroughTenth();
    await progress.box.close();
    await Hive.openBox<MAzkarProgress>(progress.boxName);

    expect(progress.resumeIndex(evening), 9);
    expect(progress.today('evening').lastItemId, 'evening_10');
  });

  test("yesterday's session is not resumed and its counts don't carry over", () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = BoxAzkarProgress.keyFor('evening', yesterday);
    await progress.box.put(
      key,
      MAzkarProgress(
        dayKey: key,
        completedCounts: {for (var i = 1; i <= 10; i++) 'evening_$i': 1},
        updatedAt: yesterday,
        lastItemId: 'evening_10',
      ),
    );

    expect(progress.resumeIndex(evening), isNull);
    expect(progress.today('evening').completedCounts, isEmpty);
  });

  test('a finished session shows the list again', () async {
    for (final item in evening.items) {
      for (var n = 0; n < item.repeat; n++) {
        await progress.increment('evening', item.id);
      }
    }
    await progress.setLastItem('evening', 'evening_12');

    expect(progress.resumeIndex(evening), isNull);
  });

  test('opening the first zekr without counting is not a session', () async {
    await progress.setLastItem('evening', 'evening_1');
    expect(progress.resumeIndex(evening), isNull);

    await progress.increment('evening', 'evening_1');
    expect(progress.resumeIndex(evening), 0);
  });

  test('a saved zekr no longer in the data is not resumed', () async {
    await progress.increment('evening', 'evening_1');
    await progress.setLastItem('evening', 'evening_99');

    expect(progress.resumeIndex(evening), isNull);
  });

  test('records saved before lastItemId existed still read', () async {
    final key = BoxAzkarProgress.keyFor('evening', DateTime.now());
    Hive.registerAdapter(_LegacyProgressAdapter(), override: true);
    await progress.box.put(
      key,
      MAzkarProgress(dayKey: key, completedCounts: {'evening_1': 1}, updatedAt: DateTime.now()),
    );
    await progress.box.close();
    Hive.registerAdapter(MAzkarProgressAdapter(), override: true);
    await Hive.openBox<MAzkarProgress>(progress.boxName);

    final stored = progress.today('evening');
    expect(stored.lastItemId, isNull);
    expect(stored.completedCounts, {'evening_1': 1});
    expect(progress.resumeIndex(evening), isNull);
  });
}
