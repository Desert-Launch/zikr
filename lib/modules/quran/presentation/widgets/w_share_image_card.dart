import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/modules/quran/domain/entities/e_ayah_share.dart';
import 'package:quran/modules/quran/domain/entities/e_share_glyph_run.dart';
import 'package:quran/modules/quran/domain/services/share_text_builder.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_line.dart'
    show arabicAyahDigits, kQpcWordBreak;
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_v4_page.dart'
    show kMushafUthmaniFamily;
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';

/// The card a shared ayah is rendered into: the verses under an illuminated
/// surah banner, any attached commentary beneath them, and the app's mark at
/// the foot.
///
/// ## Two deliberate departures from the app's UI rules
///
/// Nothing here is sized in `screenutil` units and nothing reads the active
/// theme. The output is a picture that leaves the device — it has to come out
/// the same on a phone and on a tablet, and it should not arrive dark because
/// the sender happens to read in dark mode. So the card is laid out in plain
/// logical pixels against [width], and painted from the fixed light palette the
/// printed Mushaf uses.
class WShareImageCard extends StatelessWidget {
  const WShareImageCard({
    required this.content,
    required this.surahName,
    required this.arabicDigits,
    this.appBadge = true,
    this.width = 380,
    super.key,
  });

  final EAyahShare content;

  /// Surah name as the reader's language writes it — the banner is the one
  /// place on the card that is not Arabic by definition.
  final String surahName;

  /// Whether verse numbers are printed in Arabic-Indic digits.
  final bool arabicDigits;

  final bool appBadge;

  /// Logical width the card is laid out at. Captured at a pixel ratio of 3,
  /// so the default lands a little over 1100px wide.
  final double width;

  static const Color _cream = Color(0xFFFBF6EA);
  static const Color _ink = Color(0xFF2B2118);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _green = Color(0xFF0A6B4F);
  static const Color _panel = Color(0xFFF2EAD8);

  /// The app's own mark, stamped on the card when the badge is on.
  ///
  /// Referenced by path rather than through `Assets.images`: the generated
  /// accessors are stale (build_runner does not run in this repo) and have no
  /// entry for this file.
  static const String logoAsset = 'assets/images/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WSurahHeader(
              title: 'سورة $surahName',
              surahNumber: content.surah.number,
              ayahCount: content.surah.totalAyah,
              height: 48,
            ),
            const SizedBox(height: 18),
            _Verses(content: content, arabicDigits: arabicDigits),
            for (final book in content.tafsir) ...[
              const SizedBox(height: 16),
              _TafsirBlock(book: book),
            ],
            if (appBadge) ...[const SizedBox(height: 16), const _Badge()],
          ],
        ),
      ),
    );
  }
}

/// The verses themselves, run together as the Mushaf sets them: one justified
/// block, with a numbered rosette where each verse ends.
///
/// Set in the Mushaf's own page glyphs when they could be resolved — the same
/// QPC-V4 faces the reader draws with, so a shared verse looks like the page it
/// was shared from — and in a text face when they could not.
class _Verses extends StatelessWidget {
  const _Verses({required this.content, required this.arabicDigits});

  final EAyahShare content;
  final bool arabicDigits;

  @override
  Widget build(BuildContext context) {
    final glyphs = content.glyphs;
    return Text.rich(
      TextSpan(
        children: glyphs.isEmpty ? _plainSpans() : _glyphSpans(glyphs),
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.amiri(
        fontSize: 21,
        height: 2,
        color: WShareImageCard._ink,
      ),
    );
  }

  /// The printed page's own glyphs.
  ///
  /// Each run is a pre-shaped word carrying no spaces of its own, so they are
  /// joined with U+200B — a zero-width break opportunity that Unicode classes
  /// transparent to shaping. Without it the line breaker has no word boundaries
  /// and splits mid-word; with it the advance widths are untouched.
  List<InlineSpan> _glyphSpans(List<EShareGlyphRun> glyphs) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < glyphs.length; i++) {
      final run = glyphs[i];
      // No joiner before a rosette or at the very end — the marker brings its
      // own spacing, and a trailing break would be a wrap opportunity into
      // nothing.
      final joiner = i == glyphs.length - 1 || run.isAyahEnd ? '' : kQpcWordBreak;
      spans.add(
        TextSpan(
          text: '${run.glyphs}$joiner',
          style: TextStyle(
            fontFamily: run.fontFamily,
            fontSize: _glyphSize,
            height: 1.95,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
      if (!run.isAyahEnd) continue;
      spans.add(
        TextSpan(
          // Thin spaces after the rosette, as the reader sets them, so the
          // next verse does not start hard against the marker.
          text: '${arabicAyahDigits(run.ayah)}\u202F\u202F',
          style: TextStyle(
            fontFamily: kMushafUthmaniFamily,
            fontSize: _glyphSize,
            height: 1.95,
            color: WShareImageCard._green,
          ),
        ),
      );
    }
    return spans;
  }

  /// Fallback for when the page fonts could not be prepared: readable Uthmani
  /// text with a drawn rosette in place of the printed one.
  List<InlineSpan> _plainSpans() => [
    for (final ayah in content.ayat) ...[
      TextSpan(text: '${ayah.text} '),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _AyahMark(
          label: shareDigits(ayah.ref.ayah, arabic: arabicDigits),
        ),
      ),
      const TextSpan(text: ' '),
    ],
  ];

  /// Point size the page glyphs are set at on the card. Larger than the text
  /// fallback because the QPC faces run small for their em.
  static const double _glyphSize = 23;
}

/// The rosette a verse number sits in when the printed one is unavailable —
/// the app's plain reading of the ornamented end-of-ayah mark.
class _AyahMark extends StatelessWidget {
  const _AyahMark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WShareImageCard._green.withValues(alpha: 0.08),
        border: Border.all(
          color: WShareImageCard._gold.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.amiri(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w700,
          color: WShareImageCard._green,
        ),
      ),
    );
  }
}

/// One attached book: its name over its commentary, set apart from the verses
/// so nobody can mistake the two for each other.
class _TafsirBlock extends StatelessWidget {
  const _TafsirBlock({required this.book});

  final EShareTafsir book;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: book.book.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: WShareImageCard._panel,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              book.book.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: WShareImageCard._green,
              ),
            ),
            const SizedBox(height: 10),
            for (final (index, paragraph) in book.paragraphs.indexed) ...[
              if (index > 0) const SizedBox(height: 10),
              Text(
                paragraph,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 13,
                  height: 1.85,
                  color: WShareImageCard._ink.withValues(alpha: 0.88),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The app's mark at the foot of the card: its logo over its name.
///
/// The URL is not printed here — it would be unclickable in a picture; it
/// rides along in the share's text instead.
class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            WShareImageCard.logoAsset,
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            // The card is captured a frame after it is built, so a logo that
            // has not finished decoding would be captured as a hole. Drawing
            // it synchronously from the cache — which the sheet warms when it
            // opens — is what stops that.
            gaplessPlayback: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'بواسطة تطبيق ${AppConfig.shareAppNameAr}',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 10,
            color: WShareImageCard._ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
