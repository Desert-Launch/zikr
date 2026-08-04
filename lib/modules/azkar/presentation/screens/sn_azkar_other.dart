import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WAzkarOtherHeader(
                  green: _green,
                  categoryCount: categories.length,
                  onBack: Modular.to.pop,
                  onQueryChanged: (q) => setState(() => _query = q),
                ),
              ),
              if (visible.isEmpty)
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
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, index) {
                      final category = visible[index];
                      return WAzkarCategoryTile(
                        title: category.nameAr,
                        count: category.items.length,
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
      ),
    );
  }
}
