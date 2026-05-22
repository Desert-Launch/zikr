import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';

class SNAzkarPlayer extends StatefulWidget {
  const SNAzkarPlayer({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<SNAzkarPlayer> createState() => _SNAzkarPlayerState();
}

class _SNAzkarPlayerState extends State<SNAzkarPlayer> {
  late final CBAzkarSession _cubit = Modular.get<CBAzkarSession>();
  final _favorites = Modular.get<BoxAzkarFavorite>();

  @override
  void initState() {
    super.initState();
    _cubit.open(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<CBAzkarSession, SAzkarSession>(
            buildWhen: (a, b) => a.category?.id != b.category?.id,
            builder: (_, s) => Text(
              s.category?.nameAr ?? '',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'azkar_reset'.tr(),
              onPressed: _cubit.resetCategory,
            ),
          ],
        ),
        body: BlocBuilder<CBAzkarSession, SAzkarSession>(
          builder: (context, state) {
            final cat = state.category;
            if (cat == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final item = state.currentItem;
            if (item == null) return const SizedBox.shrink();
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    value: (state.itemIndex + 1) / cat.items.length,
                    backgroundColor: context.brand.border,
                    color: AppColorsLight.primary,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Text(
                        '${state.itemIndex + 1} / ${cat.items.length}',
                        style: TextStyle(
                          fontSize: 12.sp, color: context.brand.muted,
                        ),
                      ),
                      const Spacer(),
                      _FavoriteButton(itemId: item.id, favorites: _favorites),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: 'reader_copy'.tr(),
                        onPressed: () => _copy(item),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _ZekrCard(item: item, state: state, onTap: _cubit.tap)),
                _ControlBar(
                  state: state,
                  onPrev: _cubit.previous,
                  onNext: _cubit.next,
                  onTap: _cubit.tap,
                ),
                SizedBox(height: 16.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copy(MAzkarItem item) async {
    await Clipboard.setData(ClipboardData(text: item.textAr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('reader_copy'.tr())),
    );
  }
}

class _ZekrCard extends StatelessWidget {
  const _ZekrCard({
    required this.item,
    required this.state,
    required this.onTap,
  });

  final MAzkarItem item;
  final SAzkarSession state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = state.countFor(item.id);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: onTap,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: context.brand.surface,
                  border: Border.all(color: context.brand.border),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.textAr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 22.sp, height: 2.0,
                        ),
                      ),
                    ),
                    if (item.source != null) ...[
                      SizedBox(height: 14.h),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColorsLight.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(item.source!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColorsLight.primaryDark,
                            )),
                      ),
                    ],
                    if (item.virtueAr != null) ...[
                      SizedBox(height: 12.h),
                      Text(item.virtueAr!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.brand.muted,
                            height: 1.6,
                          )),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text('azkar_repeat_label'.tr(),
                  style: TextStyle(
                    fontSize: 11.sp, color: context.brand.muted,
                  )),
              SizedBox(height: 4.h),
              Text('$completed / ${item.repeat}',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: state.isComplete(item)
                        ? AppColorsLight.success
                        : AppColorsLight.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.state,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  final SAzkarSession state;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: state.itemIndex > 0 ? onPrev : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: context.brand.background,
              foregroundColor: AppColorsLight.primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text('azkar_tap_to_count'.tr(),
                    style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: (state.category != null &&
                    state.itemIndex < state.category!.items.length - 1)
                ? onNext
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            style: IconButton.styleFrom(
              backgroundColor: context.brand.background,
              foregroundColor: AppColorsLight.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.itemId, required this.favorites});
  final String itemId;
  final BoxAzkarFavorite favorites;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool get _isFav => widget.favorites.isFavorite(widget.itemId);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
        color: _isFav ? AppColorsLight.error : null,
      ),
      onPressed: () async {
        await widget.favorites.toggle(widget.itemId);
        if (mounted) setState(() {});
      },
    );
  }
}
