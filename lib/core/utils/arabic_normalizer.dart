/// Arabic text normalisation used to match adhkar text across data sources.
///
/// Different adhkar corpora spell the same dhikr differently: they disagree on
/// tashkeel, on hamza carriers (`أ` vs `ا`), on `ة` vs `ه`, on `ى` vs `ي`, and
/// they wrap Qur'anic quotations in different bracket glyphs (`﴿﴾`, `(( ))`).
/// [normalize] strips everything presentational so two spellings of the same
/// dhikr collapse to one string, while keeping every consonant that carries
/// meaning — the point is to match *the same* dhikr, never to blur two
/// different ones together.
///
/// Nothing here mutates app data: the app's adhkar text is always rendered as
/// authored. Normalisation exists only inside the matching pipeline.
class ArabicNormalizer {
  ArabicNormalizer._();

  /// Harakat + tanween (U+064B–U+065F), superscript alef (U+0670), and the
  /// Qur'anic annotation block (U+06D6–U+06ED).
  static final RegExp _diacritics = RegExp(
    '[ً-ٰٟۖ-ۭ]',
  );

  /// Kashida (U+0640) — pure typography.
  static const String _tatweel = 'ـ';

  /// Bracket / quote / separator glyphs, Arabic and Latin, plus the Qur'anic
  /// ornate parentheses `﴿﴾` and the `*` some corpora use as an ayah separator.
  static final RegExp _punctuation = RegExp(
    '[،؛؟٪-٭۔' // ، ؛ ؟ ٪٫٬٭ ۔
    '﴾﴿‹›«»' // ﴾ ﴿ ‹ › « »
    r'''()\[\]{}<>.,;:!?*"'`\-_/\\|~^&+=%#@$'''
    '–—‘’“”…]', // – — ‘ ’ “ ” …
  );

  /// Anything that is not an Arabic letter (U+0621–U+064A) or whitespace:
  /// Latin letters, Arabic-Indic and Latin digits (verse numbers such as `(1)`
  /// leak in as bare digits once the brackets are gone), and stray symbols.
  static final RegExp _nonArabic = RegExp(r'[^ء-ي\s]');

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Word stems that mark a dhikr as belonging to the morning.
  static const List<String> _morningStems = <String>['اصبح'];
  static const List<String> _morningWords = <String>['الصباح', 'صباح'];

  /// Word stems that mark a dhikr as belonging to the evening. `امسي` is a
  /// prefix (امسينا / امسيت / امسيتم / امسي) and deliberately does not catch
  /// unrelated words such as `امسك`.
  static const List<String> _eveningStems = <String>['امسي'];
  static const List<String> _eveningWords = <String>['المساء', 'مساء'];

  /// Collapses [input] to a comparable skeleton. Returns `''` for null/blank.
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';
    var s = input;
    s = s.replaceAll(_diacritics, '');
    s = s.replaceAll(_tatweel, '');
    // Alef family → bare alef. Wasla (`ٱ`) included: corpora disagree on it.
    s = s.replaceAll('أ', 'ا'); // أ → ا
    s = s.replaceAll('إ', 'ا'); // إ → ا
    s = s.replaceAll('آ', 'ا'); // آ → ا
    s = s.replaceAll('ٱ', 'ا'); // ٱ → ا
    s = s.replaceAll('ى', 'ي'); // ى → ي
    s = s.replaceAll('ة', 'ه'); // ة → ه
    s = s.replaceAll('ؤ', 'و'); // ؤ → و
    s = s.replaceAll('ئ', 'ي'); // ئ → ي
    s = s.replaceAll('ک', 'ك'); // Persian kaf → ك
    s = s.replaceAll('ی', 'ي'); // Persian ya  → ي
    s = s.replaceAll(_punctuation, ' ');
    s = s.replaceAll(_nonArabic, ' ');
    s = s.replaceAll(_whitespace, ' ').trim();
    return s;
  }

  /// Whitespace-separated tokens of the normalised form.
  static List<String> tokens(String? input) {
    final n = normalize(input);
    if (n.isEmpty) return const <String>[];
    return n.split(' ');
  }

  /// Sørensen–Dice coefficient over token *multisets* (0.0 – 1.0).
  ///
  /// Multiset rather than set, so a dhikr repeating a word three times does not
  /// score as identical to one saying it once — repetition is meaningful here.
  static double similarity(String? a, String? b) {
    final ta = tokens(a);
    final tb = tokens(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final counts = <String, int>{};
    for (final t in ta) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    var intersection = 0;
    for (final t in tb) {
      final left = counts[t] ?? 0;
      if (left > 0) {
        counts[t] = left - 1;
        intersection++;
      }
    }
    return (2 * intersection) / (ta.length + tb.length);
  }

  /// Time-of-day markers found in [input] (`morning` and/or `evening`).
  ///
  /// Morning and evening adhkar are the *same* words with `أصبح…` swapped for
  /// `أمسى…`, so their normalised forms sit around 0.9 similarity — high enough
  /// that a purely statistical matcher would happily attach a morning
  /// recitation to an evening dhikr and play the wrong words. Callers veto such
  /// a pairing via [hasTemporalConflict].
  static Set<String> temporalMarkers(String? input) {
    final found = <String>{};
    for (final raw in tokens(input)) {
      // Strip a leading conjunction: `والمساء` and `وأمسينا` are the same
      // markers as `المساء` and `أمسينا`. Without this, a chapter titled
      // "أذكار الصباح والمساء" reads as morning-only.
      final token = (raw.length > 2 && raw.startsWith('و'))
          ? raw.substring(1)
          : raw;
      if (_morningWords.contains(token) ||
          _morningStems.any(token.startsWith)) {
        found.add('morning');
      }
      if (_eveningWords.contains(token) ||
          _eveningStems.any(token.startsWith)) {
        found.add('evening');
      }
    }
    return found;
  }

  /// True when [a] and [b] each carry exactly one time-of-day marker and those
  /// markers differ.
  ///
  /// A text carrying *both* markers (`اللهم بك أصبحنا وبك أمسينا`) conflicts
  /// with nothing: it is the same words at either time of day.
  static bool hasTemporalConflict(String? a, String? b) {
    final ma = temporalMarkers(a);
    final mb = temporalMarkers(b);
    if (ma.length != 1 || mb.length != 1) return false;
    return ma.first != mb.first;
  }
}
