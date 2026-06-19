import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_header.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_list_title.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_zekr_list_card.dart';

class SNAzkarCategory extends StatefulWidget {
  const SNAzkarCategory({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<SNAzkarCategory> createState() => _SNAzkarCategoryState();
}

class _SNAzkarCategoryState extends State<SNAzkarCategory> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final Future<MAzkarCategory?> _future = Modular.get<DSLocalAzkar>()
      .category(widget.categoryId);
  late final BoxAzkarFavorite _favorites = Modular.get<BoxAzkarFavorite>();
  late final BoxAzkarProgress _progress = Modular.get<BoxAzkarProgress>();

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: FutureBuilder<MAzkarCategory?>(
        future: _future,
        builder: (_, snapshot) {
          final category = snapshot.data;
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (category == null) return const SizedBox.shrink();
          final completed = _completedCount(category);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WAzkarHeader(
                  green: _green,
                  categoryCount: category.items.length,
                  completedToday: completed,
                  favorites: _favorites.all().length,
                  onBack: Modular.to.pop,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
                sliver: SliverList.separated(
                  itemCount: category.items.length + 1,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return WAzkarListTitle(
                        title: _categoryName(category),
                        onBack: Modular.to.pop,
                      );
                    }
                    final itemIndex = index - 1;
                    final item = category.items[itemIndex];
                    return WAzkarZekrListCard(
                      item: item,
                      favorite: _favorites.isFavorite(item.id),
                      gold: _gold,
                      onFavorite: () async {
                        await _favorites.toggle(item.id);
                        if (mounted) setState(() {});
                      },
                      onTap: () async {
                        await Modular.to.pushNamed(
                          AzkarRoutes.fullPlayer(category.id, item: itemIndex),
                        );
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _categoryName(MAzkarCategory category) {
    return LocalizeAndTranslate.getLanguageCode() == 'ar'
        ? category.nameAr
        : category.nameEn;
  }

  int _completedCount(MAzkarCategory category) {
    final counts = _progress.today(category.id).completedCounts;
    return category.items
        .where((item) => (counts[item.id] ?? 0) >= item.repeat)
        .length;
  }
}
