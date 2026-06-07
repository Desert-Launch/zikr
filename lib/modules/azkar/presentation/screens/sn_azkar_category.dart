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
    return Scaffold(
      backgroundColor: _canvas,
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
                child: _CategoryHeader(
                  category: category,
                  completed: completed,
                  favorites: _favorites.all().length,
                  green: _green,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
                sliver: SliverList.separated(
                  itemCount: category.items.length + 1,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return _ListTitle(category: category);
                    }
                    final itemIndex = index - 1;
                    final item = category.items[itemIndex];
                    return _ZekrListCard(
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

  int _completedCount(MAzkarCategory category) {
    final counts = _progress.today(category.id).completedCounts;
    return category.items
        .where((item) => (counts[item.id] ?? 0) >= item.repeat)
        .length;
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.completed,
    required this.favorites,
    required this.green,
  });

  final MAzkarCategory category;
  final int completed;
  final int favorites;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 204.h,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: const Text('🤲'),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'azkar_header_title'.tr(),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'azkar_header_subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: Modular.to.pop,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _Stat(value: favorites, label: 'azkar_favorites'.tr()),
                SizedBox(width: 9.w),
                _Stat(value: completed, label: 'azkar_completed_today'.tr()),
                SizedBox(width: 9.w),
                _Stat(
                  value: category.items.length,
                  label: 'azkar_items_suffix'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(color: Colors.white, fontSize: 18.sp),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTitle extends StatelessWidget {
  const _ListTitle({required this.category});

  final MAzkarCategory category;

  @override
  Widget build(BuildContext context) {
    final title = LocalizeAndTranslate.getLanguageCode() == 'ar'
        ? category.nameAr
        : category.nameEn;
    return Row(
      children: [
        TextButton.icon(
          onPressed: Modular.to.pop,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: Text('azkar_back_categories'.tr()),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _ZekrListCard extends StatelessWidget {
  const _ZekrListCard({
    required this.item,
    required this.favorite,
    required this.gold,
    required this.onFavorite,
    required this.onTap,
  });

  final MAzkarItem item;
  final bool favorite;
  final Color gold;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18.r,
                color: favorite ? Colors.red : Colors.grey[600],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item.textAr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 16.sp, height: 1.65),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 4.h,
                    alignment: WrapAlignment.end,
                    children: [
                      if (item.source?.isNotEmpty == true)
                        _Tag(text: item.source!, color: gold),
                      if (item.virtueAr?.isNotEmpty == true)
                        _Tag(
                          text: item.virtueAr!,
                          color: const Color(0xFF007A58),
                          outlined: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 17.r,
              backgroundColor: const Color(0xFFFF7A21),
              child: Text(
                '${item.repeat}',
                style: TextStyle(color: Colors.white, fontSize: 11.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, this.outlined = false});

  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(12.r),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.25))
            : null,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: outlined ? color : Colors.black87,
          fontSize: 8.sp,
        ),
      ),
    );
  }
}
