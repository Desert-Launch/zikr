import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/core/utils/helper/day_change_watcher.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';

void main() {
  late Directory tempDir;
  final box = BoxTasbihCounter();
  const yesterday = '20000101';

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('tasbih_counter_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(MTasbihCounterAdapter());
    await Hive.openBox<MTasbihCounter>(box.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() => box.box.clear());

  group('BoxTasbihCounter.today', () {
    test('wipes a salawat count left over from an earlier day', () {
      box.current(BoxTasbihCounter.salawatKey)
        ..count = 250
        ..target = 1000
        ..reminderIntervalHours = 2
        ..countsDay = yesterday;

      final c = box.today(BoxTasbihCounter.salawatKey);

      expect(c.count, 0);
      expect(c.countsDay, BoxTasbihCounter.dayKey(DateTime.now()));
      // Settings survive the reset.
      expect(c.target, 1000);
      expect(c.reminderIntervalHours, 2);
    });

    test('wipes an undated salawat count (records from before the stamp)', () {
      box.current(BoxTasbihCounter.salawatKey).count = 40;

      expect(box.today(BoxTasbihCounter.salawatKey).count, 0);
    });

    test("keeps today's salawat count", () {
      box.today(BoxTasbihCounter.salawatKey).count = 17;

      expect(box.today(BoxTasbihCounter.salawatKey).count, 17);
    });

    test("wipes yesterday's tasbih phrase counts but keeps the phrase", () {
      box.current()
        ..zekrAr = 'الْحَمْدُ لِلَّهِ'
        ..phraseCounts = {'الْحَمْدُ لِلَّهِ': 20}
        ..countsDay = yesterday;

      final c = box.today();

      expect(c.phraseCounts, isEmpty);
      expect(c.zekrAr, 'الْحَمْدُ لِلَّهِ');
    });

    test('the two records reset independently', () {
      box.today().phraseCounts['سُبْحَانَ اللَّهِ'] = 10;
      box.current(BoxTasbihCounter.salawatKey)
        ..count = 5
        ..countsDay = yesterday;

      expect(box.today(BoxTasbihCounter.salawatKey).count, 0);
      expect(box.today().phraseCounts['سُبْحَانَ اللَّهِ'], 10);
    });
  });

  group('DayChangeWatcher.untilNextDay', () {
    test('lands on the next local midnight', () {
      final now = DateTime(2026, 10, 7, 23, 59, 30);
      expect(DayChangeWatcher.untilNextDay(now), const Duration(seconds: 30));
    });

    test('rolls over month and year ends', () {
      final now = DateTime(2026, 12, 31, 12);
      final next = now.add(DayChangeWatcher.untilNextDay(now));
      expect(next, DateTime(2027));
    });
  });
}
