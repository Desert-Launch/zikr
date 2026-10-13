import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/adhan/services/adhan_window_diff.dart';

void main() {
  group('AdhanWindowDiff.between', () {
    const planned = {1: 'a', 2: 'b', 3: 'c'};

    test('an untrusted pass re-arms every planned entry, cancels only stale', () {
      final diff = AdhanWindowDiff.between(
        planned: planned,
        queued: const {1: 'a', 2: 'b', 3: 'c', 9: 'z'},
        trustQueued: false,
      );
      expect(diff.toSchedule, {1, 2, 3});
      expect(diff.toCancel, {9});
    });

    test('a trusted pass over an unchanged window touches nothing', () {
      final diff = AdhanWindowDiff.between(
        planned: planned,
        queued: const {1: 'a', 2: 'b', 3: 'c'},
        trustQueued: true,
      );
      expect(diff.toSchedule, isEmpty);
      expect(diff.toCancel, isEmpty);
    });

    test('a trusted pass schedules only new, changed and missing entries', () {
      final diff = AdhanWindowDiff.between(
        planned: const {1: 'a', 2: 'b2', 3: 'c', 4: 'd'},
        queued: const {1: 'a', 2: 'b', 5: 'e'},
        trustQueued: true,
      );
      // 2 changed, 3 was dropped by the OS, 4 is new; 5 left the plan.
      expect(diff.toSchedule, {2, 3, 4});
      expect(diff.toCancel, {5});
    });

    test('entries queued without a fingerprint are re-armed', () {
      final diff = AdhanWindowDiff.between(
        planned: const {1: 'a'},
        queued: const {1: null},
        trustQueued: true,
      );
      expect(diff.toSchedule, {1});
      expect(diff.toCancel, isEmpty);
    });
  });

  group('AdhanWindowDiff.fingerprint', () {
    test('is FNV-1a over the joined parts — stable across runs', () {
      // Published FNV-1a 32-bit test vector for "a". Pinned because the value
      // is stored in queued notifications and read back by later processes.
      expect(AdhanWindowDiff.fingerprint(const ['a']), 'e40c292c');
    });

    test('changes when any part changes, including its position', () {
      final base = AdhanWindowDiff.fingerprint(const [1, 'title', true]);
      expect(AdhanWindowDiff.fingerprint(const [1, 'title', true]), base);
      expect(AdhanWindowDiff.fingerprint(const [2, 'title', true]), isNot(base));
      expect(AdhanWindowDiff.fingerprint(const [1, 'title', false]), isNot(base));
      expect(AdhanWindowDiff.fingerprint(const ['title', 1, true]), isNot(base));
    });

    test('a null part is distinct from an empty string part', () {
      expect(
        AdhanWindowDiff.fingerprint(const ['x', null]),
        isNot(AdhanWindowDiff.fingerprint(const ['x', ''])),
      );
    });
  });
}
