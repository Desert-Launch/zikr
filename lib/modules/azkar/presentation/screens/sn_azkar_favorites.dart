import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_favorite_tile.dart';

class SNAzkarFavorites extends StatefulWidget {
  const SNAzkarFavorites({super.key});

  @override
  State<SNAzkarFavorites> createState() => _SNAzkarFavoritesState();
}

class _SNAzkarFavoritesState extends State<SNAzkarFavorites> {
  late final CBAzkarAudio _audio = Modular.get<CBAzkarAudio>();

  @override
  void initState() {
    super.initState();
    // Favourites span categories, so the play control needs the global index.
    _audio.prepareAudioIndex();
  }

  @override
  Widget build(BuildContext context) {
    final box = Modular.get<BoxAzkarFavorite>();
    final ds = Modular.get<DSLocalAzkar>();
    return BlocProvider.value(
      value: _audio,
      child: WSharedScaffold(
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
      ),
    );
  }
}
