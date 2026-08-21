import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/azkar/domain/services/azkar_source_text_cleaner.dart';

void main() {
  const cleaner = AzkarSourceTextCleaner();

  test('unwraps the doubled parentheses around a dhikr', () {
    expect(
      cleaner.clean('((سُبْحَانَ اللَّهِ وَبِحَمْدِهِ))'),
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    );
  });

  test('drops a trailing repetition note outside the wrapper', () {
    expect(
      cleaner.clean('((اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ)) (عشرَ مرَّاتٍ)'),
      'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    );
  });

  test('drops an unwrapped trailing note after the closing parens', () {
    expect(
      cleaner.clean('((لاَ إِلَهَ إِلاَّ اللَّهُ)) عَشْرَ مَرّاتٍ بَعْدَ الصُّبْحِ'),
      'لاَ إِلَهَ إِلاَّ اللَّهُ',
    );
  });

  test('drops a count note nested inside the dhikr', () {
    expect(
      cleaner.clean('((أَسْتَغْفِرُ اللَّهَ (ثَلاَثَاً) اللَّهُمَّ أَنْتَ السَّلاَمُ))'),
      'أَسْتَغْفِرُ اللَّهَ اللَّهُمَّ أَنْتَ السَّلاَمُ',
    );
  });

  test('drops the bracketed evening-variant note', () {
    final cleaned = cleaner.clean(
      '((أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ)) '
      '[وإذا أمسى قال: أمسينا وأمسى الملك للَّه]',
    );
    expect(cleaned, 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ');
    // The point of removing it: the text is now unambiguously a morning one,
    // so the matcher's time-of-day guard can actually fire.
    expect(cleaned.contains('أمسينا'), isFalse);
  });

  test('keeps a long parenthetical — that is quoted content, not a note', () {
    const input =
        '(اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبْثِ وَالْخَبَائِثِ وَمِنْ شَرِّ مَا خَلَقْتَ)';
    expect(cleaner.clean(input).contains('الْخُبْثِ'), isTrue);
  });

  test('reduces an instruction-only entry to nothing', () {
    // Real corpus row: brackets all the way down, no recitable words.
    expect(
      cleaner.clean('[ ((يَنْفُثُ عَنْ يَسَارِهِ)) - ((لاَ يُحَدِّثْ بِهَا أَحَداً)) ]'),
      '',
    );
  });

  test('handles null and empty input', () {
    expect(cleaner.clean(null), '');
    expect(cleaner.clean(''), '');
  });

  test('leaves a plain dhikr untouched', () {
    const plain = 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور';
    expect(cleaner.clean(plain), plain);
  });
}
