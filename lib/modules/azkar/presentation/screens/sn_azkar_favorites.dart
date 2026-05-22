import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';

class SNAzkarFavorites extends StatelessWidget {
  const SNAzkarFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Modular.get<BoxAzkarFavorite>();
    final ds = Modular.get<DSLocalAzkar>();
    return Scaffold(
      appBar: AppBar(
        title: Text('azkar_favorites'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable,
        builder: (context, _, __) {
          final favorites = box.all().toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('azkar_favorites_empty'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp, color: context.brand.muted,
                    )),
              ),
            );
          }
          return FutureBuilder<List<MAzkarCategory>>(
            future: ds.allCategories(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: favorites.length,
                itemBuilder: (_, i) => _FavoriteTile(
                  fav: favorites[i],
                  ds: ds,
                  onRemove: () => box.toggle(favorites[i].itemId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.fav,
    required this.ds,
    required this.onRemove,
  });

  final MAzkarFavorite fav;
  final DSLocalAzkar ds;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MAzkarItem?>(
      future: ds.item(fav.itemId),
      builder: (_, snap) {
        final item = snap.data;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.brand.border),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item?.source ?? fav.itemId,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColorsLight.primaryDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded,
                          color: AppColorsLight.error),
                      onPressed: onRemove,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item?.textAr ?? '—',
                    style: GoogleFonts.amiri(
                      fontSize: 16.sp, height: 1.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
