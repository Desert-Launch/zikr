import 'package:quran/modules/quran/domain/entities/rub_starts.dart';

/// Which hizb [page] is in, and how far into it — named the way the mushaf's
/// margin names it: `الحزب 23` at the hizb's own start, then `ربع الحزب 23`,
/// `نصف الحزب 23`, `ثلاثة أرباع الحزب 23` as each rub' mark is passed.
///
/// Shared by the two places that label a page: the reader's top bar and the
/// running head printed at the top of the page itself, so the two can never
/// word the same division differently.
String mushafHizbLabel(int page) {
  const prefixes = ['الحزب', 'ربع الحزب', 'نصف الحزب', 'ثلاثة أرباع الحزب'];
  final rub = RubStarts.numberForPage(page);
  return '${prefixes[RubStarts.quarterOf(rub) - 1]} ${RubStarts.hizbOf(rub)}';
}
