import 'package:localize_and_translate/localize_and_translate.dart';

/// Converts Western digits (and the `,` thousands separator) to Arabic-Indic
/// glyphs when the active locale is Arabic; returns the input untouched
/// otherwise.
String localizeQiblaDigits(String input) {
  if (LocalizeAndTranslate.getLanguageCode() != 'ar') return input;
  const western = '0123456789,';
  const arabic = '٠١٢٣٤٥٦٧٨٩٬';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final index = western.indexOf(ch);
    buffer.write(index == -1 ? ch : arabic[index]);
  }
  return buffer.toString();
}
