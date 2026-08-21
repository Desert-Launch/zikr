import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Mushaf-style banner shown at the beginning of every surah.
///
/// The printed Madani Mushaf frames a surah's name in an illuminated band: a
/// field of colour inside a double gold rule, an ogee cartouche holding the
/// name, a rosette medallion at each end carrying the surah's number and its
/// number of verses, and a small ornament bridging the two. This reproduces
/// that arrangement.
///
/// ## Everything here is drawn in one virtual coordinate space
///
/// The whole banner — painter, medallions, title — is designed against a
/// [_designHeight]-tall box and then scaled by `height / _designHeight`. That is
/// what lets the banner take a single height knob and stay in proportion: the
/// previous version pinned its ornaments to absolute pixel radii while its box
/// was sized in `.h` units, so every ornament drifted out of place the moment
/// the banner was any height but the one it was tuned at, and a tablet drew
/// phone-sized medallions on a banner half again as tall.
class WSurahHeader extends StatelessWidget {
  const WSurahHeader({
    required this.title,
    this.surahNumber,
    this.ayahCount,
    this.dark = false,
    this.height,
    super.key,
  });

  final String title;

  /// Shown in the start-side (right, in RTL) medallion — the surah's place in
  /// the Mushaf.
  final int? surahNumber;

  /// Shown in the end-side medallion — how many verses the surah has.
  final int? ayahCount;
  final bool dark;

  /// Banner height. Defaults to [_defaultHeight]; everything inside scales with
  /// it, so this is the only number that needs touching to make the banner
  /// heavier or slimmer.
  final double? height;

  /// The coordinate space every measurement below is expressed in.
  static const double _designHeight = 64;

  static double get _defaultHeight => 60.h;

  @override
  Widget build(BuildContext context) {
    final h = height ?? _defaultHeight;
    // Virtual→logical scale. Every constant from here down is a design-space
    // number multiplied by this.
    final k = h / _designHeight;

    final gold = dark ? const Color(0xFFE3C463) : const Color(0xFFC9A227);
    final goldDeep = dark ? const Color(0xFFB08D2E) : const Color(0xFF9A7A1B);
    final green = dark ? const Color(0xFF0B4034) : const Color(0xFF0A6B4F);
    final greenDeep = dark ? const Color(0xFF06291F) : const Color(0xFF064F3A);
    final cream = dark ? const Color(0xFF16241D) : const Color(0xFFFFFAEC);
    final textColor = dark ? const Color(0xFFF4EACB) : AppColorsLight.primaryDark;

    return SizedBox(
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MushafHeaderPainter(
                green: green,
                greenDeep: greenDeep,
                cream: cream,
                gold: gold,
                goldDeep: goldDeep,
                scale: k,
              ),
            ),
          ),
          // The name, inside the cartouche. FittedBox rather than an ellipsis:
          // a surah name is not a string to truncate, and the longest of them
          // ("الممتحنة", "المطففين") only needs a few percent to fit.
          Positioned(
            left: _cartoucheInset * k,
            right: _cartoucheInset * k,
            top: 0,
            bottom: 0,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * k),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      color: textColor,
                      fontSize: 23 * k,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (ayahCount != null)
            Positioned(
              left: _medallionInset * k,
              top: _medallionTop * k,
              width: _medallionSize * k,
              height: _medallionSize * k,
              child: _Medallion(
                value: ayahCount!,
                green: green,
                cream: cream,
                gold: gold,
                goldDeep: goldDeep,
                scale: k,
              ),
            ),
          if (surahNumber != null)
            Positioned(
              right: _medallionInset * k,
              top: _medallionTop * k,
              width: _medallionSize * k,
              height: _medallionSize * k,
              child: _Medallion(
                value: surahNumber!,
                green: green,
                cream: cream,
                gold: gold,
                goldDeep: goldDeep,
                scale: k,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Design-space geometry -------------------------------------------------
//
// All in the 64-unit-tall virtual space described on [WSurahHeader].

const double _medallionSize = 48;
const double _medallionInset = 9;
const double _medallionTop = 8;

/// Where the cartouche starts, measured from each edge — clear of the
/// medallions and of the ornament that bridges the gap.
const double _cartoucheInset = 86;

/// Centre of the little ornament between a medallion and the cartouche. Sits
/// clear of both: the medallion ends at 57, the cartouche's point reaches 73.
const double _ornamentCentre = 65;

class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.value,
    required this.green,
    required this.cream,
    required this.gold,
    required this.goldDeep,
    required this.scale,
  });

  final int value;
  final Color green;
  final Color cream;
  final Color gold;
  final Color goldDeep;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MedallionPainter(cream: cream, green: green, gold: gold, goldDeep: goldDeep, scale: scale),
      child: Center(
        child: Padding(
          // Keeps a three-digit count ("٢٨٦") inside the cream field instead of
          // riding over the gold rule.
          padding: EdgeInsets.symmetric(horizontal: 9 * scale),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _arabicDigits(value),
              style: GoogleFonts.amiri(color: green, fontSize: 17 * scale, fontWeight: FontWeight.w700, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// The end rosette: a ring of lobes behind a gold disc, then green, cream, and a
/// hairline rule — the layering a printed medallion is built from.
class _MedallionPainter extends CustomPainter {
  const _MedallionPainter({
    required this.cream,
    required this.green,
    required this.gold,
    required this.goldDeep,
    required this.scale,
  });

  final Color cream;
  final Color green;
  final Color gold;
  final Color goldDeep;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    const centre = Offset(_medallionSize / 2, _medallionSize / 2);

    // Twelve lobes, alternating a hair in radius so the edge reads as
    // scalloped rather than as a cog.
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final r = i.isEven ? 4.4 : 3.6;
      canvas.drawCircle(
        Offset(centre.dx + math.cos(angle) * 19.5, centre.dy + math.sin(angle) * 19.5),
        r,
        Paint()..color = i.isEven ? gold : goldDeep,
      );
    }

    canvas.drawCircle(centre, 20.5, Paint()..color = gold);
    canvas.drawCircle(centre, 18.6, Paint()..color = green);
    canvas.drawCircle(centre, 16.6, Paint()..color = cream);
    canvas.drawCircle(
      centre,
      15.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = gold,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) =>
      old.cream != cream || old.green != green || old.gold != gold || old.goldDeep != goldDeep || old.scale != scale;
}

class _MushafHeaderPainter extends CustomPainter {
  const _MushafHeaderPainter({
    required this.green,
    required this.greenDeep,
    required this.cream,
    required this.gold,
    required this.goldDeep,
    required this.scale,
  });

  final Color green;
  final Color greenDeep;
  final Color cream;
  final Color gold;
  final Color goldDeep;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    // The banner's own width, expressed in design units.
    final w = size.width / scale;
    _paintDesign(canvas, w);
    canvas.restore();
  }

  void _paintDesign(Canvas canvas, double w) {
    const top = 2.0;
    const bottom = 62.0;
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(1, top, w - 1, bottom), const Radius.circular(5));

    // A vertical gradient rather than a flat fill: it is what stops the band
    // reading as a plastic rectangle, and it costs one Paint.
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [green, greenDeep],
        ).createShader(body.outerRect),
    );

    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = gold;
    canvas.drawRRect(body, rule);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body.outerRect.deflate(3.5), const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = gold.withValues(alpha: 0.7),
    );

    // Skipped on a banner too narrow to hold it without crowding the cartouche
    // — a squeezed ornament reads as a mistake, an absent one as restraint.
    if (w > _cartoucheInset * 2 + 80) {
      _paintOrnament(canvas, _ornamentCentre);
      _paintOrnament(canvas, w - _ornamentCentre);
    }

    _paintCartouche(canvas, w);
  }

  /// The bridge between a medallion and the cartouche: a stacked column of
  /// lozenges with a dot above and below, which is the filler a printed banner
  /// uses in exactly this position.
  void _paintOrnament(Canvas canvas, double cx) {
    final fill = Paint()..color = gold.withValues(alpha: 0.9);
    final faint = Paint()..color = gold.withValues(alpha: 0.55);

    for (final spec in const [(24.0, 2.4), (32.0, 3.4), (40.0, 2.4)]) {
      final (cy, r) = spec;
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.72, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.72, cy)
          ..close(),
        fill,
      );
    }
    canvas.drawCircle(Offset(cx, 17), 1.1, faint);
    canvas.drawCircle(Offset(cx, 47), 1.1, faint);
  }

  /// The name plaque: a long panel closed at each end with an ogee point.
  void _paintCartouche(Canvas canvas, double w) {
    final path = _cartouchePath(w, inset: 0);
    canvas.drawPath(path, Paint()..color = cream);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = gold,
    );
    canvas.drawPath(
      _cartouchePath(w, inset: 3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = goldDeep.withValues(alpha: 0.65),
    );
  }

  Path _cartouchePath(double w, {required double inset}) {
    final left = _cartoucheInset - 6 + inset;
    final right = w - _cartoucheInset + 6 - inset;
    final top = 8.0 + inset;
    final bottom = 56.0 - inset;
    const mid = 32.0;
    // Half-height of the flat run before each end tapers to its point.
    const shoulder = 7.0;
    final point = 7.0 - inset * 0.6;
    final corner = 13.0;

    return Path()
      ..moveTo(left + corner, top)
      ..lineTo(right - corner, top)
      // End cap, right: shoulder in, then out to the point and back.
      ..cubicTo(right - 3, top, right, top + 5, right, mid - shoulder)
      ..quadraticBezierTo(right + point, mid, right, mid + shoulder)
      ..cubicTo(right, bottom - 5, right - 3, bottom, right - corner, bottom)
      ..lineTo(left + corner, bottom)
      ..cubicTo(left + 3, bottom, left, bottom - 5, left, mid + shoulder)
      ..quadraticBezierTo(left - point, mid, left, mid - shoulder)
      ..cubicTo(left, top + 5, left + 3, top, left + corner, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _MushafHeaderPainter old) =>
      old.green != green ||
      old.greenDeep != greenDeep ||
      old.cream != cream ||
      old.gold != gold ||
      old.goldDeep != goldDeep ||
      old.scale != scale;
}

String _arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) => digits[int.parse(digit)]).join();
}
