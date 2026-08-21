import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/services/azkar_audio_matcher.dart';

AzkarMatchTarget _target(
  String id,
  String text, {
  String category = 'morning',
  String categoryName = 'أذكار الصباح',
}) => AzkarMatchTarget(
  adhkarId: id,
  categoryId: category,
  categoryName: categoryName,
  text: text,
);

AzkarMatchCandidate _candidate(
  String id,
  String text, {
  String? categoryName,
}) => AzkarMatchCandidate(
  sourceId: id,
  text: text,
  categoryName: categoryName,
);

void main() {
  const matcher = AzkarAudioMatcher();

  group('level 1 — manual override', () {
    test('wins over everything else', () {
      const overriding = AzkarAudioMatcher(
        manualOverrides: <String, String>{'morning_1': 'src_b'},
      );
      final results = overriding.matchAll(
        [_target('morning_1', 'سبحان الله وبحمده')],
        [
          _candidate('src_a', 'سبحان الله وبحمده'),
          _candidate('src_b', 'نص مختلف تماما عن الأول'),
        ],
      );
      expect(results.single.candidate?.sourceId, 'src_b');
      expect(results.single.confidence, EAzkarAudioMatch.manual);
      expect(results.single.reason, AzkarMatchReason.manualOverride);
    });

    test('is ignored when it points at a record that no longer exists', () {
      const overriding = AzkarAudioMatcher(
        manualOverrides: <String, String>{'morning_1': 'gone'},
      );
      final results = overriding.matchAll(
        [_target('morning_1', 'سبحان الله وبحمده')],
        [_candidate('src_a', 'سبحان الله وبحمده')],
      );
      expect(results.single.confidence, EAzkarAudioMatch.exact);
    });
  });

  group('level 2 — exact normalised text', () {
    test('matches through tashkeel and bracket differences', () {
      final results = matcher.matchAll(
        [_target('morning_1', 'سبحان الله وبحمده')],
        [_candidate('src_a', '((سُبْحَانَ اللَّهِ وَبِحَمْدِهِ))')],
      );
      expect(results.single.confidence, EAzkarAudioMatch.exact);
      expect(results.single.candidate?.sourceId, 'src_a');
    });

    test('two adhkar with identical text may share one recording', () {
      final results = matcher.matchAll(
        [
          _target('morning_1', 'آية الكرسي نص مطابق تماما هنا'),
          _target(
            'evening_1',
            'آية الكرسي نص مطابق تماما هنا',
            category: 'evening',
            categoryName: 'أذكار المساء',
          ),
        ],
        [_candidate('src_a', 'آية الكرسي نص مطابق تماما هنا')],
      );
      expect(results.every((r) => r.candidate?.sourceId == 'src_a'), isTrue);
    });
  });

  group('level 3 — ties broken by category name', () {
    test('picks the source chapter that reads like the app category', () {
      final results = matcher.matchAll(
        [
          _target(
            'sleeping_6',
            'اللهم عالم الغيب والشهادة',
            category: 'sleeping',
            categoryName: 'أذكار النوم',
          ),
        ],
        [
          _candidate(
            'src_morning',
            'اللهم عالم الغيب والشهادة',
            categoryName: 'أذكار الصباح والمساء',
          ),
          _candidate(
            'src_sleep',
            'اللهم عالم الغيب والشهادة',
            categoryName: 'أذكار النوم',
          ),
        ],
      );
      expect(results.single.candidate?.sourceId, 'src_sleep');
      expect(results.single.confidence, EAzkarAudioMatch.high);
      expect(
        results.single.reason,
        AzkarMatchReason.ambiguousResolvedByCategory,
      );
    });

    test('an unbreakable tie still resolves — the words are identical', () {
      final results = matcher.matchAll(
        [_target('morning_1', 'أعوذ بكلمات الله التامات', categoryName: 'قسم')],
        [
          _candidate('src_a', 'أعوذ بكلمات الله التامات', categoryName: 'باب أ'),
          _candidate('src_b', 'أعوذ بكلمات الله التامات', categoryName: 'باب ب'),
        ],
      );
      expect(results.single.candidate?.sourceId, 'src_a');
      // Recorded as `high`, never `exact`: the choice among equals was ours.
      expect(results.single.confidence, EAzkarAudioMatch.high);
      expect(results.single.reason, AzkarMatchReason.ambiguousUnresolved);
    });
  });

  group('level 4 — fuzzy', () {
    test('accepts a clear winner above the threshold', () {
      final results = matcher.matchAll(
        [
          _target(
            'morning_1',
            'اللهم عالم الغيب والشهادة فاطر السماوات والأرض رب كل شيء ومليكه أشهد أن لا إله إلا أنت',
          ),
        ],
        [
          _candidate(
            'src_a',
            'اللهم عالم الغيب والشهادة فاطر السموات والأرض رب كل شيء ومليكه أشهد أن لا إله إلا أنت',
          ),
          _candidate('src_b', 'الحمد لله رب العالمين'),
        ],
      );
      expect(results.single.confidence, EAzkarAudioMatch.high);
      expect(results.single.reason, AzkarMatchReason.fuzzyHigh);
    });

    test('reports — never ships — a merely plausible pair', () {
      final results = matcher.matchAll(
        [_target('after_pray_1', 'سبحان الله والحمد لله والله أكبر وبحمده كثيرا')],
        [_candidate('src_a', 'سبحان الله والحمد لله والله أكبر')],
      );
      expect(results.single.candidate, isNull);
      expect(results.single.isAccepted, isFalse);
      expect(results.single.reason, AzkarMatchReason.needsReview);
    });

    test('reports nothing at all when no candidate is close', () {
      final results = matcher.matchAll(
        [_target('morning_1', 'اللهم إني أسألك علما نافعا ورزقا طيبا')],
        [_candidate('src_a', 'بسم الله الذي لا يضر مع اسمه شيء في الأرض')],
      );
      expect(results.single.reason, AzkarMatchReason.noCandidate);
      expect(results.single.isAccepted, isFalse);
    });
  });

  group('time-of-day veto', () {
    test('refuses to hand an evening dhikr a morning recitation', () {
      final results = matcher.matchAll(
        [
          _target(
            'evening_9',
            'اللهم إني أمسيت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت',
            category: 'evening',
            categoryName: 'أذكار المساء',
          ),
        ],
        [
          _candidate(
            'src_morning',
            'اللهم إني أصبحت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت',
          ),
        ],
      );
      final result = results.single;
      expect(result.isAccepted, isFalse);
      expect(result.reason, AzkarMatchReason.temporalConflict);
      // The score alone would have sailed past the threshold — the veto is
      // what stops the wrong words playing.
      expect(result.score, greaterThan(0.92));
    });

    test('still matches the morning dhikr it really belongs to', () {
      final results = matcher.matchAll(
        [
          _target(
            'morning_8',
            'اللهم إني أصبحت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت',
          ),
        ],
        [
          _candidate(
            'src_morning',
            'اللهم إني أصبحت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت',
          ),
        ],
      );
      expect(results.single.confidence, EAzkarAudioMatch.exact);
    });
  });

  test('an empty dhikr is reported, not silently matched', () {
    final results = matcher.matchAll(
      [_target('other_1', '   ')],
      [_candidate('src_a', 'سبحان الله')],
    );
    expect(results.single.reason, AzkarMatchReason.emptyText);
    expect(results.single.isAccepted, isFalse);
  });

  test('no candidates at all yields no matches', () {
    final results = matcher.matchAll(
      [_target('morning_1', 'سبحان الله')],
      const <AzkarMatchCandidate>[],
    );
    expect(results.single.isAccepted, isFalse);
  });
}
