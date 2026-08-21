import 'package:quran/core/utils/arabic_normalizer.dart';

/// Strips *book apparatus* from an external adhkar corpus before matching.
///
/// Printed adhkar collections carry editorial furniture the reciter never says:
/// the dhikr itself sits inside `(( … ))`, repetition and timing notes trail it
/// (`(ثلاث مرات)`, `عشر مرات بعد صلاة المغرب`), and square brackets hold a note
/// about the evening variant (`[وإذا أمسى قال: أمسينا …]`).
///
/// Leaving that in costs matches twice over: it drags similarity below the
/// acceptance threshold for pairs that are genuinely the same dhikr, and the
/// bracketed evening note plants an `أمسى` in an otherwise morning-only text,
/// which blinds the time-of-day guard. Removing it makes both the score and the
/// guard reflect what is actually recited.
class AzkarSourceTextCleaner {
  const AzkarSourceTextCleaner();

  /// Editorial notes: `[…]`, always dropped whole.
  static final RegExp _brackets = RegExp(r'\[[^\]]*\]');

  /// The dhikr proper, wrapped in doubled parentheses.
  static final RegExp _wrapped = RegExp(r'^\(\((.*)\)\)', dotAll: true);

  /// A parenthetical group, non-greedy.
  static final RegExp _parenthetical = RegExp(r'\(([^()]*)\)');

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Words that make a parenthetical a repetition/timing note rather than part
  /// of the dhikr. Compared against the *normalised* form, so `مرَّاتٍ` and
  /// `مرات` are the same token.
  static final RegExp _annotation = RegExp(
    'مره|مرات|مرتين|ثلاثا|سبعا|عشرا|ثلاثين|وثلاثين|'
    'اذا اصبح|اذا امسي|اذا اويت|كل يوم',
  );

  String clean(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    var text = raw.replaceAll(_brackets, ' ');

    // Everything after the dhikr's closing `))` is commentary on how often and
    // when to say it — never part of the words.
    final wrapped = _wrapped.firstMatch(text.trim());
    if (wrapped != null) {
      text = wrapped.group(1) ?? text;
    }

    text = text.replaceAllMapped(_parenthetical, (m) {
      final inner = m.group(1) ?? '';
      return _isAnnotation(inner) ? ' ' : m.group(0) ?? '';
    });

    text = text.replaceAll('((', ' ').replaceAll('))', ' ');
    return text.replaceAll(_whitespace, ' ').trim();
  }

  /// A short parenthetical whose words are a count or a time-of-day cue.
  bool _isAnnotation(String inner) {
    final normalized = ArabicNormalizer.normalize(inner);
    if (normalized.isEmpty) return false;
    // Long parentheticals are quoted content, not a note.
    if (normalized.split(' ').length > 6) return false;
    return _annotation.hasMatch(normalized);
  }
}
