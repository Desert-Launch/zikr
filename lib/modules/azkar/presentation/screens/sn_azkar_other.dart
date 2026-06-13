import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

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
                child: _Header(
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
                    return _CategoryTile(
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

class _Header extends StatelessWidget {
  const _Header({
    required this.green,
    required this.categoryCount,
    required this.onBack,
  });

  final Color green;
  final int categoryCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
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
                  'azkar_other_title'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$categoryCount ${'azkar_categories'.tr()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10.sp,
                  ),
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
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded, color: Colors.grey[400], size: 20.r),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '$count ${'azkar_items_suffix'.tr()}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: const Color(0xFFFF0B68).withValues(alpha: 0.12),
              child: Text('📿', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
