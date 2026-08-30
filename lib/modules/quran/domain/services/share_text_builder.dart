import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_share.dart';

/// Ornamental brackets the printed Mushaf puts around quoted revelation, and
/// the end-of-ayah mark that separates one verse from the next inside them.
const String _openQuote = '﴿';
const String _closeQuote = '﴾';
const String _ayahSeparator = '۝';

/// Renders a resolved share as the text that leaves the app.
///
/// ```
/// ﴿…لَعَلَّهُم يَفقَهونَ ۝ وَكَذَّبَ بِهِ…﴾ [الأنعام: ٦٥-٦٧]
///
/// المختصر في التفسير:
/// قل لهم - أيها الرسول -: …
///
/// بواسطة تطبيق ذِكر
/// https://zikr.app
/// ```
///
/// Deliberately free of `.tr()` and of anything that reads app state: the
/// caller passes the already-localized [surahName] and [viaLabel], which keeps
/// this the single formatter both the text share and the image card can agree
/// on.
String buildShareText({
  required EAyahShare content,
  required String surahName,
  required String viaLabel,
  required bool arabicDigits,
  bool stripTashkeel = false,
  bool appBadge = true,
}) {
  if (content.ayat.isEmpty) return '';

  final verses = content.ayat
      .map((a) => stripTashkeel ? stripArabicDiacritics(a.text) : a.text)
      .join(' $_ayahSeparator ');
  final buffer = StringBuffer()
    ..write(_openQuote)
    ..write(verses)
    ..write(_closeQuote)
    ..write(' [')
    ..write(surahName)
    ..write(': ')
    ..write(shareAyahRange(content, arabic: arabicDigits))
    ..write(']');

  for (final book in content.tafsir) {
    if (book.isEmpty) continue;
    buffer
      ..write('\n\n')
      ..write(book.book.name)
      ..write(':\n')
      ..write(book.paragraphs.join('\n'));
  }

  if (appBadge) {
    buffer
      ..write('\n\n')
      ..write(viaLabel)
      ..write('\n')
      ..write(AppConfig.shareAppUrl);
  }

  return buffer.toString();
}

/// The verse range as it is printed after the surah name: `٦٥` for one verse,
/// `٦٥-٦٧` for several.
String shareAyahRange(EAyahShare content, {required bool arabic}) {
  final from = shareDigits(content.from, arabic: arabic);
  if (content.from == content.to) return from;
  return '$from-${shareDigits(content.to, arabic: arabic)}';
}

/// [value] in Arabic-Indic digits when [arabic], Western otherwise.
///
/// A deliberate twin of `arabicDigits` in `mushaf_labels.dart`: that one labels
/// the printed page and lives in the presentation layer, and the domain does
/// not reach up into it.
String shareDigits(int value, {required bool arabic}) {
  if (!arabic) return '$value';
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

/// Takes the harakat off Uthmani text without touching the letters.
///
/// Unlike the search normaliser this keeps alif variants, ta marbuta and alif
/// maqsura exactly as written — the point is text that still reads as the
/// Quran, only unvocalised, not text flattened for matching.
String stripArabicDiacritics(String input) {
  final buffer = StringBuffer();
  for (final code in input.runes) {
    // Harakat and tanwin (064B–065F), superscript alef (0670), the Quranic
    // annotation signs (06D6–06ED) and tatweel (0640).
    if ((code >= 0x064B && code <= 0x065F) ||
        code == 0x0670 ||
        (code >= 0x06D6 && code <= 0x06ED) ||
        code == 0x0640) {
      continue;
    }
    buffer.writeCharCode(code);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
