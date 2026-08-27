import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_highlighted_ayah.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_page_pill.dart';

/// One text-search hit: where the verse is, then the verse itself with the
/// matched words picked out.
class WSearchHitTile extends StatelessWidget {
  const WSearchHitTile({super.key, required this.hit, required this.query, this.onTap});
  final SearchHit hit;
  final String query;

  /// Overrides the default behaviour (push a fresh reader). The inline reader
  /// search passes a callback that jumps within the open reader instead.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final tap = onTap;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: WSearchCard(
        onTap: tap ??
            () => Modular.to.pushNamed(
                  QuranRoutes.readerFromAyah(hit.ref.surah, hit.ref.ayah),
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Where it is: surah then ayah on the reading side, page opposite.
            Row(
              children: [
                // Grouped so the surah name may claim every pixel the chip and
                // the pill leave behind, rather than splitting the slack with
                // a spacer.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _surahTitle(isRtl),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: brand.onSurface,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _AyahChip(ayah: hit.ref.ayah, isRtl: isRtl),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                WSearchPagePill(page: hit.page),
              ],
            ),
            SizedBox(height: 10.h),
            // The verse itself — highlighted match, always RTL, behind a quote
            // rule on the reading edge. The trailing ayah-end number is dropped;
            // it's already shown in the header.
            Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(
                    color: brand.primary.withValues(alpha: 0.3),
                    width: 2.5.w,
                  ),
                ),
              ),
              padding: EdgeInsetsDirectional.only(start: 10.w),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: WHighlightedAyah(text: _verseText, query: query),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The verse text with the trailing ayah-end number marker removed
  /// (Arabic-Indic / extended digits + the end-of-ayah ornament U+06DD).
  String get _verseText => hit.snippet
      .replaceFirst(RegExp(r'[٠-٩۰-۹۝\s]+$'), '')
      .trimRight();

  /// Picks the most readable surah name for the active direction, falling back
  /// to the other script and finally to the raw reference.
  String _surahTitle(bool isRtl) {
    final ar = hit.surahArabicName.trim();
    final en = hit.surahName.trim();
    final fallback = '${hit.ref.surah}:${hit.ref.ayah}';
    if (!isRtl) return ar.isNotEmpty ? ar : (en.isNotEmpty ? en : fallback);
    return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : fallback);
  }
}

/// The verse number, set in a soft chip so it reads as a label rather than as
/// part of the surah name next to it.
class _AyahChip extends StatelessWidget {
  const _AyahChip({required this.ayah, required this.isRtl});

  final int ayah;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final label = 'search_ayah'
        .tr()
        .replaceFirst('{{ayah}}', isRtl ? arabicDigits(ayah) : '$ayah');
    return Container(
      decoration: BoxDecoration(
        color: brand.surfaceMuted,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: brand.muted,
        ),
      ),
    );
  }
}
