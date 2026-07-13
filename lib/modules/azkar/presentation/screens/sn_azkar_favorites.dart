import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_favorite_tile.dart';

class SNAzkarFavorites extends StatelessWidget {
  const SNAzkarFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Modular.get<BoxAzkarFavorite>();
    final ds = Modular.get<DSLocalAzkar>();
    return WSharedScaffold(
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          WGradientAppBar(title: 'azkar_favorites'.tr()),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable,
              builder: (context, _, __) {
                final favorites = box.all().toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                if (favorites.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        'azkar_favorites_empty'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.brand.muted,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: favorites.length,
                  itemBuilder: (_, i) => WAzkarFavoriteTile(
                    fav: favorites[i],
                    ds: ds,
                    onRemove: () => box.toggle(favorites[i].itemId),
                    onOpen: (categoryId, itemIndex) => Modular.to.pushNamed(
                      AzkarRoutes.fullPlayer(categoryId, item: itemIndex),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
