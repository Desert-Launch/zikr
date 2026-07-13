import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

/// A favorited zekr card. Resolves its text/repeat/category lazily from [ds] by
/// item id and, when tapped, reopens the counter screen at that zekr.
class WAzkarFavoriteTile extends StatelessWidget {
  const WAzkarFavoriteTile({
    super.key,
    required this.fav,
    required this.ds,
    required this.onRemove,
    required this.onOpen,
  });

  final MAzkarFavorite fav;
  final DSLocalAzkar ds;
  final VoidCallback onRemove;
  final void Function(String categoryId, int itemIndex) onOpen;

  @override
  Widget build(BuildContext context) {
    final isAr = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return FutureBuilder<({MAzkarItem item, MAzkarCategory category, int index})?>(
      future: ds.locate(fav.itemId),
      builder: (_, snap) {
        final located = snap.data;
        final item = located?.item;
        // Prefer the name stored on the favorite; fall back to the resolved
        // category for legacy favorites saved before names were persisted.
        final categoryName = (isAr ? fav.categoryNameAr : fav.categoryNameEn) ??
            (isAr ? located?.category.nameAr : located?.category.nameEn);
        final categoryId = fav.categoryId ?? located?.category.id;
        final itemIndex = fav.itemIndex ?? located?.index;
        final repeat = item?.repeat ?? 0;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.brand.border),
            borderRadius: BorderRadius.circular(14.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: (categoryId != null && itemIndex != null)
                ? () => onOpen(categoryId, itemIndex)
                : null,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (categoryName != null && categoryName.isNotEmpty)
                        Expanded(
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColorsLight.primaryDark,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (repeat > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColorsLight.primaryDark.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'x$repeat',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColorsLight.primaryDark,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.favorite_rounded, color: AppColorsLight.error),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item?.textAr ?? '—',
                      style: GoogleFonts.amiri(fontSize: 16.sp, height: 1.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
