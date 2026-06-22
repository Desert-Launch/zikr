import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/widgets/w_highlighted_ayah.dart';

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

    final ayahLabel = 'search_ayah'.tr().replaceFirst('{{ayah}}', _digits(hit.ref.ayah, isRtl));
    final pageLabel = 'search_page'.tr().replaceFirst('{{page}}', _digits(hit.page, isRtl));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: tap ?? () => Modular.to.pushNamed(QuranRoutes.readerFromAyah(hit.ref.surah, hit.ref.ayah)),
        child: Container(
          decoration: BoxDecoration(
            color: brand.surface,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(color: brand.onSurface.withValues(alpha: 0.05), blurRadius: 8.r, offset: Offset(0, 4.h)),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                  _Dot(color: brand.muted),
                  SizedBox(width: 8.w),
                  Text(
                    ayahLabel,
                    style: TextStyle(fontSize: 12.sp, color: brand.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              // The verse itself — highlighted match, always RTL. The trailing
              // ayah-end number is dropped; it's already shown in the header.
              Directionality(
                textDirection: TextDirection.rtl,
                child: WHighlightedAyah(text: _verseText, query: query),
              ),
              SizedBox(height: 10.h),
              // Footer meta: page reference.
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 13.r, color: brand.muted),
                  SizedBox(width: 4.w),
                  Text(
                    pageLabel,
                    style: TextStyle(fontSize: 11.sp, color: brand.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
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

  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Renders [n] with Arabic-Indic digits when showing the RTL/Arabic UI.
  String _digits(int n, bool toArabic) {
    if (!toArabic) return '$n';
    return '$n'.split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _arabicDigits[d];
    }).join();
  }
}

/// Small separator dot between the surah name and the ayah label.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.r,
      height: 3.r,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
    );
  }
}
