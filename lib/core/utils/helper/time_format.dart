/// Shared time-of-day formatting so prayer times render consistently across
/// the home card, the prayer screen, and the prayer list.
class TimeFormat {
  TimeFormat._();

  /// 12-hour clock with an AM/PM marker, e.g. `05:43 ص` / `01:10 م`.
  ///
  /// Defaults to the Arabic markers (ص = AM, م = PM) to match the app's
  /// Arabic-first UI. Pass [arabicMarker] = false for Latin `AM`/`PM`.
  static String hm12(DateTime dt, {bool arabicMarker = true}) {
    final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final isPm = dt.hour >= 12;
    final marker = arabicMarker ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');
    return '${_two(hour12)}:${_two(dt.minute)} $marker';
  }

  /// 12-hour clock with no AM/PM marker and no leading zero on the hour,
  /// e.g. `5:43` / `1:10`. Matches the minimalist time styling in the home
  /// prayer banner.
  static String h12Plain(DateTime dt) {
    final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$hour12:${_two(dt.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
