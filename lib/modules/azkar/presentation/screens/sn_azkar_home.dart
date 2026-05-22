import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

class SNAzkarHome extends StatefulWidget {
  const SNAzkarHome({super.key});

  @override
  State<SNAzkarHome> createState() => _SNAzkarHomeState();
}

class _SNAzkarHomeState extends State<SNAzkarHome> {
  late final Future<List<MAzkarCategory>> _future =
      Modular.get<DSLocalAzkar>().allCategories();

  IconData _iconFor(String id) => switch (id) {
        'morning' => Icons.wb_sunny_outlined,
        'evening' => Icons.brightness_4_outlined,
        'sleep' => Icons.bedtime_outlined,
        'after_prayer' => Icons.mosque_outlined,
        'general' => Icons.format_quote_outlined,
        _ => Icons.format_list_bulleted_rounded,
      };

  Color _colorFor(String id) => switch (id) {
        'morning' => const Color(0xFFF59E0B),
        'evening' => const Color(0xFF8B5CF6),
        'sleep' => const Color(0xFF3B82F6),
        'after_prayer' => AppColorsLight.primary,
        'general' => const Color(0xFF10B981),
        _ => AppColorsLight.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('azkar_title'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            tooltip: 'azkar_favorites'.tr(),
            onPressed: () => Modular.to.pushNamed(AzkarRoutes.fullFavorites()),
          ),
        ],
      ),
      body: FutureBuilder<List<MAzkarCategory>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snap.data!;
          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: cats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, i) {
              final c = cats[i];
              final color = _colorFor(c.id);
              return InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () => Modular.to.pushNamed(AzkarRoutes.fullPlayer(c.id)),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: context.brand.surface,
                    border: Border.all(color: context.brand.border),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(_iconFor(c.id), color: color, size: 24.r),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nameAr,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                              )),
                          SizedBox(height: 2.h),
                          Text('${c.items.length} ${'azkar_items_suffix'.tr()}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: context.brand.muted,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
