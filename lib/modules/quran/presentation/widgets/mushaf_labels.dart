import 'package:quran/modules/quran/domain/entities/rub_starts.dart';

/// Which hizb [page] is in, and how far into it — named the way the mushaf's
/// margin names it: `الحزب 23` at the hizb's own start, then `ربع الحزب 23`,
/// `نصف الحزب 23`, `ثلاثة أرباع الحزب 23` as each rub' mark is passed.
///
/// Shared by the two places that label a page: the reader's top bar and the
/// running head printed at the top of the page itself, so the two can never
/// word the same division differently.
String mushafHizbLabel(int page) {
  final rub = RubStarts.numberForPage(page);
  return mushafRubLabel(RubStarts.hizbOf(rub), RubStarts.quarterOf(rub));
}

/// How the mushaf names [quarter] (1..4) of [hizb] (1..60): `الحزب 23` at the
/// hizb's own start, then `ربع الحزب 23`, `نصف الحزب 23` and
/// `ثلاثة أرباع الحزب 23`.
String mushafRubLabel(int hizb, int quarter) {
  const prefixes = ['الحزب', 'ربع الحزب', 'نصف الحزب', 'ثلاثة أرباع الحزب'];
  return '${prefixes[quarter - 1]} ${arabicDigits(hizb)}';
}

/// [value] in Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩).
///
/// The page's own chrome — its juz', its rub' and its folio number — is part of
/// the printed Mushaf, not part of the app's UI, and a printed Mushaf sets those
/// numbers in the same digits as the ayah rosettes on the page above them.
/// Western digits in the running head next to Arabic-Indic ones in the text was
/// the one thing on the page that came from a different book.
String arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}
