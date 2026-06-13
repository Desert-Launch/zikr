import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_catalog.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_category_card.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_header.dart';

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
  late final Future<_AzkarHomeData> _future = _load();

  /// Per-category accent colors, keyed by the asset slug. Emoji comes from the
  /// catalog JSON; colors stay here so the data file holds only content.
  static const _colors = {
    'morning': Color(0xFFFF7A21),
    'evening': Color(0xFF7137F5),
    'wakeing_up': Color(0xFFF5A623),
    'sleeping': Color(0xFF098FD8),
    'after_pray': Color(0xFF09A981),
    'masged': Color(0xFF0A7E8C),
    'other_azkar': Color(0xFFFF0B68),
  };

  Future<_AzkarHomeData> _load() async {
    final catalog = await _local.catalog();
    final daily = await _local.allCategories();
    return _AzkarHomeData(catalog: catalog, daily: daily);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: FutureBuilder<_AzkarHomeData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final byId = {for (final c in data.daily) c.id: c};
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WAzkarHeader(
                  green: _green,
                  categoryCount: data.catalog.length,
                  completedToday: _completedToday(data.daily),
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
                    childAspectRatio: 1.13,
                  ),
                  delegate: SliverChildListDelegate([
                    ...data.catalog.map(
                      (entry) => WAzkarCategoryCard(
                        title: _catalogName(entry),
                        count: entry.isOther ? -1 : (byId[entry.slug]?.items.length ?? 0),
                        color: _colorFor(entry.slug),
                        emoji: entry.emoji,
                        onTap: entry.isOther ? _openOther : () => _openCategory(entry.slug),
                      ),
                    ),
                    WAzkarCategoryCard(
                      title: 'azkar_favorites'.tr(),
                      count: _favorites.all().length,
                      color: const Color(0xFFFF841D),
                      emoji: '📖',
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

  Color _colorFor(String slug) => _colors[slug] ?? _green;

  String _catalogName(MAzkarCatalog entry) {
    return LocalizeAndTranslate.getLanguageCode() == 'ar' ? entry.nameAr : entry.nameEn;
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

  Future<void> _openOther() async {
    await Modular.to.pushNamed(AzkarRoutes.fullOther());
    if (mounted) setState(() {});
  }

  Future<void> _openFavorites() async {
    await Modular.to.pushNamed(AzkarRoutes.fullFavorites());
    if (mounted) setState(() {});
  }
}

class _AzkarHomeData {
  const _AzkarHomeData({required this.catalog, required this.daily});

  final List<MAzkarCatalog> catalog;
  final List<MAzkarCategory> daily;
}
