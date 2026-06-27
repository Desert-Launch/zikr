import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Mushaf-style banner shown at the beginning of every surah.
class WSurahHeader extends StatelessWidget {
  const WSurahHeader({required this.title, this.surahNumber, this.ayahCount, this.dark = false, super.key});

  final String title;
  final int? surahNumber;
  final int? ayahCount;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final gold = dark ? const Color(0xFFE0BD4A) : const Color(0xFFC9A227);
    final green = dark ? const Color(0xFF083D31) : const Color(0xFF086B50);
    final cream = dark ? const Color(0xFF17251E) : const Color(0xFFFFFAEC);
    final textColor = dark ? const Color(0xFFF4EACB) : AppColorsLight.primaryDark;

    return Container(
      width: double.infinity,
      height: 64.h,
      margin: EdgeInsets.symmetric(vertical: 15.h),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MushafHeaderPainter(green: green, cream: cream, gold: gold),
            ),
          ),
          Positioned.fill(
            left: 92.w,
            right: 92.w,
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(color: textColor, fontSize: 20.sp, fontWeight: FontWeight.w700, height: 1),
              ),
            ),
          ),
          if (ayahCount != null)
            Positioned(
              left: 20.w,
              top: 10.h,
              child: _Medallion(caption: 'عدد آياتها', value: ayahCount!, green: green, cream: cream, gold: gold),
            ),
          if (surahNumber != null)
            Positioned(
              right: 20.w,
              top: 10.h,
              child: _Medallion(caption: 'ترتيبها', value: surahNumber!, green: green, cream: cream, gold: gold),
            ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.caption,
    required this.value,
    required this.green,
    required this.cream,
    required this.gold,
  });

  final String caption;
  final int value;
  final Color green;
  final Color cream;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.w,
      height: 44.h,
      child: CustomPaint(
        painter: _MedallionPainter(cream: cream, green: green, gold: gold),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              caption,
              maxLines: 1,
              style: GoogleFonts.amiri(color: green, fontSize: 6.5.sp, fontWeight: FontWeight.w700, height: 0.85),
            ),
            SizedBox(height: 1.h),
            Text(
              _arabicDigits(value),
              style: GoogleFonts.amiri(color: green, fontSize: 14.sp, fontWeight: FontWeight.w700, height: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter({required this.cream, required this.green, required this.gold});

  final Color cream;
  final Color green;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * 18, center.dy + math.sin(angle) * 18),
        4.2,
        Paint()..color = gold,
      );
    }
    canvas.drawCircle(center, 19.5, Paint()..color = gold);
    canvas.drawCircle(center, 18, Paint()..color = green);
    canvas.drawCircle(center, 16.2, Paint()..color = cream);
    canvas.drawCircle(
      center,
      14.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = gold,
    );
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) => old.cream != cream || old.green != green || old.gold != gold;
}

String _arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) => digits[int.parse(digit)]).join();
}

class _MushafHeaderPainter extends CustomPainter {
  const _MushafHeaderPainter({required this.green, required this.cream, required this.gold});

  final Color green;
  final Color cream;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 3, size.width - 1, size.height - 6),
      const Radius.circular(1),
    );
    canvas.drawRRect(outer, Paint()..color = green);

    final goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = gold;
    canvas.drawRRect(outer, goldStroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.outerRect.deflate(4), const Radius.circular(1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = gold.withValues(alpha: 0.75),
    );

    _drawSidePattern(canvas, size, left: true);
    _drawSidePattern(canvas, size, left: false);

    final center = _centerPlaque(size);
    canvas.drawPath(center, Paint()..color = cream);
    canvas.drawPath(center, goldStroke);
    canvas.drawPath(
      _centerPlaque(size, inset: 4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = gold.withValues(alpha: 0.65),
    );
  }

  Path _centerPlaque(Size size, {double inset = 0}) {
    final sideWidth = math.min(88.0, size.width * 0.24);
    final left = sideWidth + inset;
    final right = size.width - sideWidth - inset;
    final top = 5 + inset;
    final bottom = size.height - 5 - inset;
    final middle = size.height / 2;
    return Path()
      ..moveTo(left + 17, top)
      ..quadraticBezierTo(left + 5, top, left + 4, middle - 12)
      ..quadraticBezierTo(left - 3, middle - 5, left - 3, middle)
      ..quadraticBezierTo(left - 3, middle + 5, left + 4, middle + 12)
      ..quadraticBezierTo(left + 5, bottom, left + 17, bottom)
      ..lineTo(right - 17, bottom)
      ..quadraticBezierTo(right - 5, bottom, right - 4, middle + 12)
      ..quadraticBezierTo(right + 3, middle + 5, right + 3, middle)
      ..quadraticBezierTo(right + 3, middle - 5, right - 4, middle - 12)
      ..quadraticBezierTo(right - 5, top, right - 17, top)
      ..close();
  }

  void _drawSidePattern(Canvas canvas, Size size, {required bool left}) {
    final sideWidth = math.min(88.0, size.width * 0.24);
    final centerX = left ? sideWidth / 2 : size.width - sideWidth / 2;
    final center = Offset(centerX, size.height / 2);
    final pattern = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = gold.withValues(alpha: 0.72);

    canvas.drawCircle(center, 21, pattern);
    canvas.drawCircle(center, 17, pattern);

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final start = Offset(center.dx + math.cos(angle) * 22, center.dy + math.sin(angle) * 22);
      final end = Offset(center.dx + math.cos(angle) * 29, center.dy + math.sin(angle) * 29);
      canvas.drawLine(start, end, pattern);
      canvas.drawCircle(end, 1.4, Paint()..color = gold);
    }

    final edgeX = left ? 10.0 : size.width - 10;
    for (var y = 13.0; y < size.height - 8; y += 12) {
      final diamond = Path()
        ..moveTo(edgeX, y - 3)
        ..lineTo(edgeX + (left ? 3 : -3), y)
        ..lineTo(edgeX, y + 3)
        ..lineTo(edgeX + (left ? -3 : 3), y)
        ..close();
      canvas.drawPath(diamond, pattern);
    }
  }

  @override
  bool shouldRepaint(covariant _MushafHeaderPainter old) =>
      old.green != green || old.cream != cream || old.gold != gold;
}
