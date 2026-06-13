import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';

/// Renders Arabic ayah text with substring matches of [query] highlighted.
/// Matching is diacritic-tolerant: we normalise both sides, then map normalised
/// indices back onto the original string by walking runes in parallel.
class WHighlightedAyah extends StatelessWidget {
  const WHighlightedAyah({super.key, required this.text, required this.query});
  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans();
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 18.sp,
          height: 1.8,
          color: context.brand.onSurface,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _buildSpans() {
    final normQuery = DSLocalQuran.normaliseForSearch(query);
    if (normQuery.isEmpty) return [TextSpan(text: text)];

    // Build a parallel mapping: for each rune index in the original, what is
    // its index in the normalised version (or null if the rune was stripped)?
    final originalRunes = text.runes.toList();
    final normaliseMap = <int, int>{}; // original-rune-index → normalised-rune-index
    final normBuf = StringBuffer();
    for (int i = 0; i < originalRunes.length; i++) {
      final normalised = DSLocalQuran.normaliseForSearch(
        String.fromCharCode(originalRunes[i]),
      );
      if (normalised.isEmpty) continue;
      normaliseMap[i] = normBuf.length;
      normBuf.write(normalised);
    }
    final norm = normBuf.toString();
    final invMap = <int, int>{}; // normalised-rune-index → original-rune-index
    normaliseMap.forEach((orig, nrm) => invMap[nrm] = orig);

    final spans = <TextSpan>[];
    int cursor = 0;
    int searchFrom = 0;
    while (true) {
      final hit = norm.indexOf(normQuery, searchFrom);
      if (hit < 0) break;
      final origStart = invMap[hit];
      final origEnd = invMap[hit + normQuery.length] ?? originalRunes.length;
      if (origStart == null) {
        searchFrom = hit + normQuery.length;
        continue;
      }
      if (origStart > cursor) {
        spans.add(TextSpan(
          text: String.fromCharCodes(originalRunes.sublist(cursor, origStart)),
        ));
      }
      spans.add(TextSpan(
        text: String.fromCharCodes(originalRunes.sublist(origStart, origEnd)),
        style: TextStyle(
          color: AppColorsLight.primary,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColorsLight.primary.withValues(alpha: 0.12),
        ),
      ));
      cursor = origEnd;
      searchFrom = hit + normQuery.length;
    }
    if (cursor < originalRunes.length) {
      spans.add(TextSpan(
        text: String.fromCharCodes(originalRunes.sublist(cursor)),
      ));
    }
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}
