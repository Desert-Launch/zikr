import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';

/// Printed-Mushaf style page chrome at the top of each page: the juz' on the
/// start side (right in RTL) and the surah's name on the end side (left).
///
/// That order is the printed one, and it is the reverse of what this used to
/// show. The rub'/hizb line that used to hang under the juz' has moved to the
/// running foot, where the print puts it — see [WMushafPageFooter]. Losing it
/// from here is what lets the head be a single line of two short labels.
///
/// Kept deliberately plain — no borders or medallions — so it reads as page
/// running-head, not a surah banner.
class WMushafPageHeader extends StatelessWidget {
  const WMushafPageHeader({required this.surahName, required this.page, required this.color, super.key});

  /// Arabic name of the surah at the top of the page.
  final String surahName;

  /// Page number (1–604) — used to derive the juz' label.
  final int page;

  /// Muted foreground that matches the page-number colour for the theme.
  final Color color;

  /// The height the running head always occupies.
  ///
  /// Fixed, and that is the point: the page reserves exactly this much, so the
  /// gap between the head and the first line is a number the page chooses
  /// ([kMushafChromeGap]) rather than whatever an even distribution happened to
  /// hand out. Derived from the type size so it tracks the device, with real
  /// headroom above the tallest label it can hold.
  static double heightOf(BuildContext context) => (context.isTablet ? 15.sp : 13.sp) * 1.7;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final size = isTablet ? 14.sp : 12.sp;

    return SizedBox(
      height: heightOf(context),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 4.w, right: 4.w),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start (right in RTL) → the juz'.
                Text(
                  'الجزء ${arabicDigits(CBMushafReader.juzForPage(page))}',
                  maxLines: 1,
                  style: TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: color),
                ),
                // End (left in RTL) → the surah name.
                Flexible(
                  child: Text(
                    surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.amiri(
                      fontSize: size + 1,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
