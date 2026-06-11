import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';

class SNAzkarPlayer extends StatefulWidget {
  const SNAzkarPlayer({
    super.key,
    required this.categoryId,
    this.itemIndex = 0,
  });

  final String categoryId;
  final int itemIndex;

  @override
  State<SNAzkarPlayer> createState() => _SNAzkarPlayerState();
}

class _SNAzkarPlayerState extends State<SNAzkarPlayer> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBAzkarSession _cubit = Modular.get<CBAzkarSession>();
  late final BoxAzkarFavorite _favorites = Modular.get<BoxAzkarFavorite>();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    await _cubit.open(widget.categoryId);
    _cubit.jumpTo(widget.itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: _canvas,
        body: BlocBuilder<CBAzkarSession, SAzkarSession>(
          builder: (_, state) {
            final category = state.category;
            final item = state.currentItem;
            if (category == null || item == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final completed = state.countFor(item.id);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CompactHeader(
                    itemCount: category.items.length,
                    completed: category.items
                        .where((item) => state.isComplete(item))
                        .length,
                    favorites: _favorites.all().length,
                    green: _green,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 28.h),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: Modular.to.pop,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: Text('azkar_back_list'.tr()),
                          ),
                          const Spacer(),
                          Text(
                            category.nameAr,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      _CounterCard(
                        item: item,
                        completed: completed,
                        green: _green,
                        onTap: _cubit.tap,
                        onReset: _cubit.resetCurrent,
                      ),
                      if (item.virtueAr?.isNotEmpty == true) ...[
                        SizedBox(height: 12.h),
                        _VirtueCard(text: item.virtueAr!, gold: _gold),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.itemCount,
    required this.completed,
    required this.favorites,
    required this.green,
  });

  final int itemCount;
  final int completed;
  final int favorites;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164.h,
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
      color: green,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  child: const Text('🤲'),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'azkar_header_title'.tr(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'azkar_header_subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 8.sp,
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
                _MiniStat(value: favorites, label: 'azkar_favorites'.tr()),
                SizedBox(width: 7.w),
                _MiniStat(
                  value: completed,
                  label: 'azkar_completed_today'.tr(),
                ),
                SizedBox(width: 7.w),
                _MiniStat(value: itemCount, label: 'azkar_items_suffix'.tr()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 7.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.item,
    required this.completed,
    required this.green,
    required this.onTap,
    required this.onReset,
  });

  final MAzkarItem item;
  final int completed;
  final Color green;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = item.repeat <= 0
        ? 0.0
        : (completed / item.repeat).clamp(0, 1).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 365.h),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                item.textAr,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 20.sp, height: 1.8),
              ),
            ),
            SizedBox(height: 28.h),
            Container(
              width: 128.r,
              height: 128.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$completed',
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '${'azkar_of'.tr()} ${item.repeat}',
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 42.w,
                    child: LinearProgressIndicator(
                      minHeight: 3.h,
                      value: progress,
                      color: green,
                      backgroundColor: const Color(0xFFE7E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 14),
              label: Text('azkar_reset_counter'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                textStyle: TextStyle(fontSize: 9.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard({required this.text, required this.gold});

  final String text;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 13.r,
            backgroundColor: gold,
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'azkar_virtue'.tr(),
            style: TextStyle(fontSize: 9.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 7.h),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 13.sp, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}
