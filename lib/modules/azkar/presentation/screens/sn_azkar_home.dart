import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';

class SNAzkarHome extends StatefulWidget {
  const SNAzkarHome({super.key});

  @override
  State<SNAzkarHome> createState() => _SNAzkarHomeState();
}

class _SNAzkarHomeState extends State<SNAzkarHome> {
  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF8F7F4);

  late final DSLocalAzkar _local = Modular.get<DSLocalAzkar>();
  late final BoxAzkarFavorite _favorites = Modular.get<BoxAzkarFavorite>();
  late final BoxAzkarProgress _progress = Modular.get<BoxAzkarProgress>();
  late final Future<List<MAzkarCategory>> _future = _local.allCategories();

  static const _order = ['morning', 'evening', 'sleep', 'after_prayer', 'general'];

  static const _styles = {
    'morning': _CategoryStyle(Color(0xFFFF7A21), '🌅'),
    'evening': _CategoryStyle(Color(0xFF7137F5), '🌙'),
    'sleep': _CategoryStyle(Color(0xFF098FD8), '🌌'),
    'after_prayer': _CategoryStyle(Color(0xFF09A981), '🕌'),
    'general': _CategoryStyle(Color(0xFFFF0B68), '🤲'),
    'favorites': _CategoryStyle(Color(0xFFFF841D), '📖'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: FutureBuilder<List<MAzkarCategory>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = _sorted(snapshot.data!);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _AzkarHeader(
                  green: _green,
                  categoryCount: categories.length + 1,
                  completedToday: _completedToday(categories),
                  favorites: _favorites.all().length,
                  onBack: Modular.to.pop,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                    childAspectRatio: 1.08,
                  ),
                  delegate: SliverChildListDelegate([
                    ...categories.map(
                      (category) => _CategoryCard(
                        title: _categoryName(category),
                        count: category.items.length,
                        style: _styles[category.id]!,
                        onTap: () => _openCategory(category.id),
                      ),
                    ),
                    _CategoryCard(
                      title: 'azkar_favorites'.tr(),
                      count: _favorites.all().length,
                      style: _styles['favorites']!,
                      onTap: _openFavorites,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MAzkarCategory> _sorted(List<MAzkarCategory> categories) {
    final result = [...categories];
    result.sort((a, b) => _order.indexOf(a.id).compareTo(_order.indexOf(b.id)));
    return result;
  }

  String _categoryName(MAzkarCategory category) {
    return LocalizeAndTranslate.getLanguageCode() == 'ar' ? category.nameAr : category.nameEn;
  }

  int _completedToday(List<MAzkarCategory> categories) {
    var completed = 0;
    for (final category in categories) {
      final counts = _progress.today(category.id).completedCounts;
      for (final item in category.items) {
        if ((counts[item.id] ?? 0) >= item.repeat) completed++;
      }
    }
    return completed;
  }

  Future<void> _openCategory(String id) async {
    await Modular.to.pushNamed(AzkarRoutes.fullCategory(id));
    if (mounted) setState(() {});
  }

  Future<void> _openFavorites() async {
    await Modular.to.pushNamed(AzkarRoutes.fullFavorites());
    if (mounted) setState(() {});
  }
}

class _AzkarHeader extends StatelessWidget {
  const _AzkarHeader({
    required this.green,
    required this.categoryCount,
    required this.completedToday,
    required this.favorites,
    required this.onBack,
  });

  final Color green;
  final int categoryCount;
  final int completedToday;
  final int favorites;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 218.h,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44.w,
            top: -52.h,
            child: _OutlineCircle(size: 150.r),
          ),
          Positioned(
            left: -42.w,
            bottom: -64.h,
            child: _OutlineCircle(size: 150.r),
          ),
          Positioned(
            right: 105.w,
            top: 62.h,
            child: _OutlineCircle(size: 92.r),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21.r,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      child: const Text('🤲', style: TextStyle(fontSize: 20)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'azkar_header_title'.tr(),
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 21.sp, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'azkar_header_subtitle'.tr(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 10.sp),
                        ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(value: favorites, label: 'azkar_favorites'.tr()),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _StatCard(value: completedToday, label: 'azkar_completed_today'.tr()),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _StatCard(value: categoryCount, label: 'azkar_categories'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  const _OutlineCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 4),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14.r)),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.count, required this.style, required this.onTap});

  final String title;
  final int count;
  final _CategoryStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: style.color.withValues(alpha: 0.25), blurRadius: 9, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -7.h,
              end: -7.w,
              child: Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Text(style.emoji, style: TextStyle(fontSize: 25.sp)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.72), size: 18.r),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$count ${'azkar_items_suffix'.tr()}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.color, this.emoji);

  final Color color;
  final String emoji;
}
