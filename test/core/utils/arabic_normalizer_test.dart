import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/utils/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer.normalize', () {
    test('strips tashkeel', () {
      expect(
        ArabicNormalizer.normalize('سُبْحَانَ اللَّهِ'),
        ArabicNormalizer.normalize('سبحان الله'),
      );
    });

    test('folds every alef variant onto a bare alef', () {
      const variants = ['أستغفر', 'إستغفر', 'آستغفر', 'ٱستغفر', 'استغفر'];
      final normalized = variants.map(ArabicNormalizer.normalize).toSet();
      expect(normalized, hasLength(1));
    });

    test('folds ta marbuta, alif maqsura and hamza carriers', () {
      expect(ArabicNormalizer.normalize('رحمة'), 'رحمه');
      expect(ArabicNormalizer.normalize('على'), 'علي');
      expect(ArabicNormalizer.normalize('مؤمن'), 'مومن');
      expect(ArabicNormalizer.normalize('سائل'), 'سايل');
    });

    test('removes tatweel', () {
      expect(ArabicNormalizer.normalize('أَسْـتَغْفِرُ'), 'استغفر');
    });

    test('drops the ornate Quranic brackets but keeps the words', () {
      expect(
        ArabicNormalizer.normalize('﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾'),
        'قل هو الله احد',
      );
    });

    test('drops verse numbers that survive bracket removal', () {
      expect(
        ArabicNormalizer.normalize('قل هو الله أحد(1) الله الصمد(2)'),
        'قل هو الله احد الله الصمد',
      );
    });

    test('collapses whitespace and newlines', () {
      expect(ArabicNormalizer.normalize('  الحمد   \n لله  '), 'الحمد لله');
    });

    test('returns empty for null, blank and non-Arabic-only input', () {
      expect(ArabicNormalizer.normalize(null), '');
      expect(ArabicNormalizer.normalize('   '), '');
      expect(ArabicNormalizer.normalize('12345 ()'), '');
    });

    test('does not merge two genuinely different adhkar', () {
      final a = ArabicNormalizer.normalize('سبحان الله وبحمده');
      final b = ArabicNormalizer.normalize('سبحان الله العظيم');
      expect(a, isNot(b));
    });
  });

  group('ArabicNormalizer.similarity', () {
    test('is 1.0 for texts that differ only in presentation', () {
      expect(
        ArabicNormalizer.similarity(
          '((سُبْحَانَ اللَّهِ وَبِحَمْدِهِ))',
          'سبحان الله وبحمده',
        ),
        1.0,
      );
    });

    test('is 0 when either side is empty', () {
      expect(ArabicNormalizer.similarity('', 'الحمد لله'), 0);
      expect(ArabicNormalizer.similarity('الحمد لله', null), 0);
    });

    test('counts repetition — a word said thrice is not the same as once', () {
      final score = ArabicNormalizer.similarity(
        'استغفر الله استغفر الله استغفر الله',
        'استغفر الله',
      );
      expect(score, lessThan(1.0));
    });

    test('falls off for unrelated text', () {
      expect(
        ArabicNormalizer.similarity('اللهم صل على محمد', 'أعوذ بكلمات الله'),
        lessThan(0.3),
      );
    });
  });

  group('ArabicNormalizer temporal markers', () {
    test('detects morning and evening wording', () {
      expect(ArabicNormalizer.temporalMarkers('أصبحنا وأصبح الملك لله'), {
        'morning',
      });
      expect(ArabicNormalizer.temporalMarkers('أمسينا وأمسى الملك لله'), {
        'evening',
      });
    });

    test('reports both when a text names both times of day', () {
      expect(
        ArabicNormalizer.temporalMarkers('اللهم بك أصبحنا وبك أمسينا'),
        {'morning', 'evening'},
      );
    });

    test('sees through a leading waw conjunction', () {
      // "أذكار الصباح والمساء" is a title covering both sittings; reading it
      // as morning-only would strand the combined recording.
      expect(ArabicNormalizer.temporalMarkers('أذكار الصباح والمساء'), {
        'morning',
        'evening',
      });
      expect(ArabicNormalizer.temporalMarkers('وأمسينا'), {'evening'});
    });

    test('does not mistake أمسك for evening wording', () {
      expect(ArabicNormalizer.temporalMarkers('فإن أمسكت نفسي فارحمها'), isEmpty);
    });

    test('vetoes a morning/evening pairing', () {
      expect(
        ArabicNormalizer.hasTemporalConflict(
          'أمسينا وأمسى الملك لله',
          'أصبحنا وأصبح الملك لله',
        ),
        isTrue,
      );
    });

    test('does not veto when a text covers both times of day', () {
      expect(
        ArabicNormalizer.hasTemporalConflict(
          'اللهم بك أصبحنا وبك أمسينا',
          'أصبحنا وأصبح الملك لله',
        ),
        isFalse,
      );
    });

    test('does not veto when neither text is time-bound', () {
      expect(
        ArabicNormalizer.hasTemporalConflict(
          'سبحان الله وبحمده',
          'سبحان الله العظيم',
        ),
        isFalse,
      );
    });
  });
}
