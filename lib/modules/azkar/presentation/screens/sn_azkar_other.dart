import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
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

  late final Future<List<MAzkarCategory>> _future =
      Modular.get<DSLocalAzkar>().otherCategories();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: FutureBuilder<List<MAzkarCategory>>(
        future: _future,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? const <MAzkarCategory>[];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WAzkarOtherHeader(
                  green: _green,
                  categoryCount: categories.length,
                  onBack: Modular.to.pop,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 28.h),
                sliver: SliverList.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final category = categories[index];
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
