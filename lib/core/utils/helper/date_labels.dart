import 'package:localize_and_translate/localize_and_translate.dart';

/// Human-readable date parts, shared by the prayer header and the home-screen
/// widget snapshot so the two can never disagree on what today is called.
///
/// Every method takes the language explicitly and only falls back to the
/// app's current one: the widget publisher renders for a language it is
/// handed, and the unit tests run without the localization plugin.
class DateLabels {
  DateLabels._();

  static const List<String> _arWeekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const List<String> _enWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  static const List<String> _enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _arHijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  static const List<String> _enHijriMonths = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Shaaban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qidah',
    'Dhu al-Hijjah',
  ];

  static bool _isArabic(String? lang) =>
      (lang ?? LocalizeAndTranslate.getLanguageCode()) == 'ar';

  /// `السبت` / `Saturday`.
  static String weekday(DateTime date, {String? lang}) =>
      (_isArabic(lang) ? _arWeekdays : _enWeekdays)[date.weekday - 1];

  /// `29 أغسطس 2026` / `29 August 2026`.
  static String gregorian(DateTime date, {String? lang}) {
    final month = (_isArabic(lang) ? _arMonths : _enMonths)[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// Weekday and Gregorian date on one line, as the widget's date row reads:
  /// `السبت، 29 أغسطس 2026` / `Saturday, 29 August 2026`.
  static String weekdayAndGregorian(DateTime date, {String? lang}) {
    final comma = _isArabic(lang) ? '،' : ',';
    return '${weekday(date, lang: lang)}$comma ${gregorian(date, lang: lang)}';
  }

  /// `15 ربيع الأول 1448 هـ` / `15 Rabi al-Awwal 1448 AH`.
  ///
  /// Tabular (arithmetic) Islamic calendar, converted through the Julian day
  /// number. It can sit a day off Umm al-Qura around a month boundary; it is
  /// used everywhere the app prints a Hijri date so at least it is off
  /// consistently.
  static String hijri(DateTime date, {String? lang}) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + (12 * a) - 3;
    final julianDay =
        date.day +
        ((153 * m + 2) ~/ 5) +
        (365 * y) +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;

    var l = julianDay - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - (10631 * n) + 354;
    final j =
        (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) +
        ((l ~/ 5670) * ((43 * l) ~/ 15238));
    l =
        l -
        (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) -
        ((j ~/ 16) * ((15238 * j) ~/ 43)) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - ((709 * month) ~/ 24);
    final year = (30 * n) + j - 30;

    final isArabic = _isArabic(lang);
    final monthName = (isArabic ? _arHijriMonths : _enHijriMonths)[month - 1];
    return isArabic ? '$day $monthName $year هـ' : '$day $monthName $year AH';
  }
}
