import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/quran/domain/entities/sajdah_marks.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';

/// Printed-Mushaf style page chrome at the foot of each page: the rub'/hizb the
/// page ends in and the folio number, one at each end of a single line.
///
/// Which end each takes flips with the page's parity, the way a printed book
/// numbers a spread: the folio number goes to the OUTER corner — right on an
/// odd (recto) page, left on an even (verso) one — and the rub' label always
/// takes the corner opposite it.
///
/// The rub' line used to ride in the running head under the juz'; it belongs
/// here, and moving it is what let the head become a single line.
///
/// The sajdah sign — on the fifteen pages that carry one — sits between the two,
/// which is the only slot left now that both ends are spoken for. It keeps its
/// own colour rather than the muted running-foot grey, because it is the one
/// thing on this line a reader must not miss.
class WMushafPageFooter extends StatelessWidget {
  const WMushafPageFooter({
    required this.page,
    required this.color,
    this.sajdahColor,
    super.key,
  });

  /// Page number (1–604) — also derives the rub' label and the sajdah marker.
  final int page;

  /// Muted foreground that matches the header colour for the theme.
  final Color color;

  /// Colour for the sajdah mark. It deliberately breaks away from [color]:
  /// the muted running-foot grey made the sign easy to miss, and a sajdah is
  /// the one thing on this line the reader must notice. Falls back to [color].
  final Color? sajdahColor;

  /// The height the running foot always occupies — the mirror of
  /// [WMushafPageHeader.heightOf], and reserved for the same reason: it lets
  /// the page set the gap above the foot itself instead of inheriting a line
  /// gap. Sized off the folio cartouche, the tallest thing on the row.
  static double heightOf(BuildContext context) =>
      (context.isTablet ? 16.sp : 12.sp) * 2.0;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final hasSajdah = SajdahMarks.onPage(page);

    final number = _PageNumber(page: page, color: color, isTablet: isTablet);
    // The ONLY flexible child on the row, which is what makes it impossible to
    // overflow: its share is everything the number and the sajdah leave behind,
    // so a long label ellipsizes instead of pushing the row past the page. And
    // because it takes only its natural width out of that share, `spaceBetween`
    // still hands the leftover back as the gap that pins it to its own edge.
    final rub = Flexible(
      child: Text(
        mushafHizbLabel(page),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: isTablet ? 13.sp : 10.sp, color: color),
      ),
    );

    return SizedBox(
      height: heightOf(context),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(left: 6.w, right: 6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // First child is the START of the row, which the RTL wrapper above
              // puts on the RIGHT.
              page.isOdd ? number : rub,

              if (hasSajdah)
                _SajdahBadge(tint: sajdahColor ?? color, isTablet: isTablet),
              page.isOdd ? rub : number,
            ],
          ),
        ),
      ),
    );
  }
}

/// The folio number, set in a miniature illuminated cartouche.
///
/// Deliberately the same silhouette as the plaque that holds the surah name in
/// [WSurahHeader] — an oblong closed with an ogee point at each end, a fill so
/// faint it barely separates from the paper, and a double rule. A page carries
/// exactly two pieces of ornament, this and the surah banner, and them being
/// obviously the same shape is what makes the page read as one designed object
/// rather than as text with widgets stuck to it.
///
/// Every colour is derived from [color] by opacity alone, so it follows the
/// reading theme through white, warm paper and night without a palette of its
/// own — a gold-on-green folio would have fought the muted running foot it sits
/// on.
class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.page,
    required this.color,
    required this.isTablet,
  });

  final int page;
  final Color color;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FolioPainter(color: color),
      child: Padding(
        // Wide enough on the sides for the ogee points to have somewhere to go
        // — they are drawn INSIDE the box, so the padding is what stops them
        // reaching the digits.
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : 13.w,
          vertical: isTablet ? 4.h : 2.h,
        ),
        child: Text(
          arabicDigits(page),
          maxLines: 1,
          // Amiri, like the surah banner's medallions: its Arabic-Indic
          // numerals are drawn for a book, and the two ornaments on the page
          // should be numbered by the same hand.
          style: GoogleFonts.amiri(
            fontSize: isTablet ? 16.sp : 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

/// Paints the folio cartouche behind the number.
class _FolioPainter extends CustomPainter {
  const _FolioPainter({required this.color});

  final Color color;

  /// How far each ogee point reaches in from the edge of the box.
  static const double _point = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= _point * 3 || size.height <= 4) return;

    final outer = _plaque(size, 0.7);
    canvas.drawPath(outer, Paint()..color = color.withValues(alpha: 0.06));
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = color.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      _plaque(size, 3.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = color.withValues(alpha: 0.3),
    );
  }

  /// An oblong closed with an ogee point at each end, [inset] in from the box.
  Path _plaque(Size size, double inset) {
    final top = inset;
    final bottom = size.height - inset;
    final mid = size.height / 2;
    final left = _point + inset;
    final right = size.width - _point - inset;
    // The tip retreats with the inset, so the inner rule stays parallel to the
    // outer one instead of poking through it.
    final tip = _point - inset * 0.55;
    final corner = math.min(6.0, (right - left) / 4);
    final shoulder = (bottom - top) * 0.22;

    return Path()
      ..moveTo(left + corner, top)
      ..lineTo(right - corner, top)
      ..cubicTo(right - 2, top, right, top + 2, right, mid - shoulder)
      ..quadraticBezierTo(right + tip, mid, right, mid + shoulder)
      ..cubicTo(right, bottom - 2, right - 2, bottom, right - corner, bottom)
      ..lineTo(left + corner, bottom)
      ..cubicTo(left + 2, bottom, left, bottom - 2, left, mid + shoulder)
      ..quadraticBezierTo(left - tip, mid, left, mid - shoulder)
      ..cubicTo(left, top + 2, left + 2, top, left + corner, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _FolioPainter old) => old.color != color;
}

class _SajdahBadge extends StatelessWidget {
  const _SajdahBadge({required this.tint, required this.isTablet});

  final Color tint;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8.w : 5.w,
        vertical: isTablet ? 3.h : 1.h,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '${SajdahMarks.sign} سجدة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // Amiri carries the sajdah sign; the platform default renders it as a
        // box on some Android builds.
        style: GoogleFonts.amiri(
          fontSize: isTablet ? 20.sp : 12.sp,
          fontWeight: FontWeight.w700,
          color: tint,
          height: 1.1,
        ),
      ),
    );
  }
}
