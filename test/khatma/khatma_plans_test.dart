import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/quran/domain/entities/rub_starts.dart';

/// Guards the bundled khatma plans: every plan must cover the whole mushaf
/// with no gap or overlap between days, and every rub'-based plan must start
/// each day on a mark the reader actually prints (`RubStarts`).
///
/// The files are produced by `tool/generate_khatma_plans.py`; this is the
/// check that a regeneration — or a hand edit — did not break them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The plan lengths the picker offers, longest first.
  const expectedDays = [240, 120, 80, 60, 40, 30, 29, 20, 15, 10, 7, 6, 5, 3];

  // Goes through the real datasource so the hand-made 365-day plan gets its
  // surah numbers resolved by name exactly as it does in the app.
  final local = DSLocalKhatma();
  late List<MKhatmaMetadata> metadata;
  late Map<int, List<MKhatmaWird>> wirdsByPlan;
  late Map<int, int> ayahCount;

  /// The ayah right after [surah]:[ayah], crossing into the next surah.
  (int, int) next(int surah, int ayah) =>
      ayah < (ayahCount[surah] ?? 0) ? (surah, ayah + 1) : (surah + 1, 1);

  setUpAll(() async {
    metadata = await local.metadata();
    wirdsByPlan = {
      for (final plan in metadata) plan.id: await local.wirds(plan),
    };
    final surahs =
        jsonDecode(await rootBundle.loadString('assets/data/surahs.json'))
            as List;
    ayahCount = {
      for (final s in surahs)
        (s as Map)['number'] as int: s['totalAyah'] as int,
    };
  });

  List<MKhatmaWird> wirdsOf(MKhatmaMetadata plan) =>
      wirdsByPlan[plan.id] ?? const [];

  test(
    'the picker offers every plan length, with 30 and 29 days suggested',
    () {
      final byDays = {for (final plan in metadata) plan.days: plan};
      for (final days in expectedDays) {
        expect(byDays, contains(days), reason: 'missing $days-day plan');
      }
      final suggested = metadata.where((p) => p.isSuggested).map((p) => p.days);
      expect(suggested, unorderedEquals([30, 29]));
    },
  );

  test('plans list suggested first, then longest to shortest', () {
    final days = metadata.map((p) => p.days).toList();
    expect(days.take(2), [30, 29]);
    final rest = days.skip(2).toList();
    expect(rest, List.of(rest)..sort((a, b) => b.compareTo(a)));
  });

  test('plan ids are unique and the original five are unchanged', () {
    final ids = metadata.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    final byDays = {for (final plan in metadata) plan.days: plan.id};
    // Persisted `MKhatmaPlan.planId` values point at these.
    expect(byDays[30], 1);
    expect(byDays[60], 2);
    expect(byDays[120], 3);
    expect(byDays[240], 4);
    expect(byDays[365], 5);
  });

  test(
    'every plan covers the mushaf once, from 1:1 to 114:6, in page order',
    () {
      for (final plan in metadata) {
        final wirds = wirdsOf(plan);
        expect(wirds.length, plan.days, reason: '${plan.path} day count');
        expect(wirds.first.startSurahNumber, 1, reason: plan.path);
        expect(wirds.first.startAyahNumber, 1, reason: plan.path);
        expect(wirds.first.startPageNumber, 1, reason: plan.path);
        expect(wirds.last.endSurahNumber, 114, reason: plan.path);
        expect(wirds.last.endAyahNumber, 6, reason: plan.path);
        expect(wirds.last.endPageNumber, 604, reason: plan.path);

        for (var i = 0; i < wirds.length; i++) {
          final wird = wirds[i];
          expect(wird.index, i + 1, reason: '${plan.path} day ${i + 1}');
          expect(
            wird.hasSurahNumbers,
            isTrue,
            reason: '${plan.path} day ${i + 1}',
          );
          expect(
            wird.startPageNumber,
            lessThanOrEqualTo(wird.endPageNumber),
            reason: '${plan.path} day ${i + 1}',
          );
          if (i + 1 < wirds.length) {
            final following = wirds[i + 1];
            expect(
              next(wird.endSurahNumber, wird.endAyahNumber),
              (following.startSurahNumber, following.startAyahNumber),
              reason:
                  '${plan.path} day ${i + 1} does not hand over to day ${i + 2}',
            );
            expect(
              wird.endPageNumber,
              lessThanOrEqualTo(following.startPageNumber),
              reason: '${plan.path} day ${i + 1}',
            );
          }
        }
      }
    },
  );

  test("rub'-based plans start every day on a printed rub' mark", () {
    final rubStarts = {
      for (final row in RubStarts.rows) '${row[0]}:${row[1]}': row[2],
    };
    for (final plan in metadata.where((p) => expectedDays.contains(p.days))) {
      for (final wird in wirdsOf(plan)) {
        final key = '${wird.startSurahNumber}:${wird.startAyahNumber}';
        expect(
          rubStarts,
          contains(key),
          reason: '${plan.path} day ${wird.index} starts off a rub\' mark',
        );
        expect(
          wird.startPageNumber,
          rubStarts[key],
          reason: '${plan.path} day ${wird.index} page',
        );
      }
    }
  });

  test(
    'plans that divide 240 evenly give every day the same number of arba\'',
    () {
      final rubIndex = {
        for (var i = 0; i < RubStarts.rows.length; i++)
          '${RubStarts.rows[i][0]}:${RubStarts.rows[i][1]}': i,
      };
      for (final plan in metadata.where(
        (p) => expectedDays.contains(p.days) && 240 % p.days == 0,
      )) {
        final perDay = 240 ~/ plan.days;
        for (final wird in wirdsOf(plan)) {
          final key = '${wird.startSurahNumber}:${wird.startAyahNumber}';
          expect(
            rubIndex[key],
            (wird.index - 1) * perDay,
            reason: '${plan.path} day ${wird.index}',
          );
        }
      }
    },
  );
}
