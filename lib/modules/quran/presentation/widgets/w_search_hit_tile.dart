import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/widgets/w_highlighted_ayah.dart';

class WSearchHitTile extends StatelessWidget {
  const WSearchHitTile({super.key, required this.hit, required this.query});
  final SearchHit hit;
  final String query;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(
        QuranRoutes.readerFromAyah(hit.ref.surah, hit.ref.ayah),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${hit.ref.surah}:${hit.ref.ayah}',
                    style: TextStyle(
                      color: AppColorsLight.primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.menu_book_outlined,
                    size: 14.r, color: context.brand.muted),
              ],
            ),
            SizedBox(height: 6.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: WHighlightedAyah(text: hit.snippet, query: query),
            ),
          ],
        ),
      ),
    );
  }
}
