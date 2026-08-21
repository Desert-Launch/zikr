import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_category_favorite.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_category_tile.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_other_header.dart';

/// Lists every category from `other_azkar.json`. Tapping one opens the shared
/// [SNAzkarCategory] list for that category's azkar.
class SNAzkarOther extends StatefulWidget {
  const SNAzkarOther({super.key});

  @override
  State<SNAzkarOther> createState() => _SNAzkarOtherState();
}

class _SNAzkarOtherState extends State<SNAzkarOther> {
  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF8F7F4);

  late final Future<List<MAzkarCategory>> _future = Modular.get<DSLocalAzkar>()
      .otherCategories();
  late final BoxAzkarCategoryFavorite _favorites =
      Modular.get<BoxAzkarCategoryFavorite>();

  String _query = '';

  /// Categories matching the live search query. Matching is done on the
  /// normalised Arabic name so diacritics and the alef variants don't block a
  /// match.
  List<MAzkarCategory> _filter(List<MAzkarCategory> all) {
    final query = _normalise(_query);
    if (query.isEmpty) return all;
    return all
        .where((c) => _normalise(c.nameAr).contains(query))
        .toList(growable: false);
  }

  /// Splits the visible categories into a favorites section pinned above the
  /// rest. Section labels are dropped entirely when nothing is favorited, so
  /// the list looks exactly as it did before the first favorite.
  List<_OtherRow> _rows(List<MAzkarCategory> visible, Set<String> favoriteIds) {
    final favorites = visible.where((c) => favoriteIds.contains(c.id));
    final rest = visible.where((c) => !favoriteIds.contains(c.id));
    if (favorites.isEmpty) {
      return [for (final c in rest) _OtherRow.category(c)];
    }
    return [
      _OtherRow.label('azkar_favorites'.tr()),
      for (final c in favorites) _OtherRow.category(c),
      if (rest.isNotEmpty) _OtherRow.label('azkar_all_categories'.tr()),
      for (final c in rest) _OtherRow.category(c),
    ];
  }

  static String _normalise(String value) => value
      .trim()
      .replaceAll(RegExp('[ً-ْٰ]'), '') // harakat
      .replaceAll(RegExp('[آأإ]'), 'ا') // alef variants
      .replaceAll('ة', 'ه') // ta marbuta → ha
      .replaceAll('ى', 'ي') // alef maqsura → ya
      .toLowerCase();

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: FutureBuilder<List<MAzkarCategory>>(
        future: _future,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? const <MAzkarCategory>[];
          final visible = _filter(categories);
          return ValueListenableBuilder(
            valueListenable: _favorites.listenable,
            builder: (_, __, ___) {
              final favoriteIds = _favorites.ids();
              final rows = _rows(visible, favoriteIds);
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: WAzkarOtherHeader(
                      green: _green,
                      categoryCount: categories.length,
                      onBack: NavHelper.back,
                      onQueryChanged: (q) => setState(() => _query = q),
                    ),
                  ),
                  if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: WEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'search_no_results_generic'.tr(),
                        isDark: false,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 28.h),
                      sliver: SliverList.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (_, index) {
                          final row = rows[index];
                          final label = row.label;
                          if (label != null) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 6.h,
                                bottom: 2.h,
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _green,
                                ),
                              ),
                            );
                          }
                          final category = row.category;
                          if (category == null) return const SizedBox.shrink();
                          return WAzkarCategoryTile(
                            title: category.nameAr,
                            count: category.items.length,
                            favorite: favoriteIds.contains(category.id),
                            onFavorite: () => _favorites.toggle(
                              category.id,
                              nameAr: category.nameAr,
                            ),
                            onTap: () => Modular.to.pushNamed(
                              AzkarRoutes.fullCategory(category.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// One entry in the browser list — either a section label or a category tile.
class _OtherRow {
  const _OtherRow.label(this.label) : category = null;
  const _OtherRow.category(this.category) : label = null;

  final String? label;
  final MAzkarCategory? category;
}
