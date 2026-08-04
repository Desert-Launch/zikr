import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';

/// Quick access to saved bookmarks from inside the reader: a compact sheet of
/// bookmarked ayahs. Picking one closes the sheet and jumps the open Mushaf to
/// that verse — no navigation away from the page you're on.
class WReaderBookmarksSheet extends StatefulWidget {
  const WReaderBookmarksSheet({super.key, required this.onOpenAyah});

  /// Called after the sheet closes, with the chosen verse.
  final ValueChanged<ParamAyahRef> onOpenAyah;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ParamAyahRef> onOpenAyah,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WReaderBookmarksSheet(onOpenAyah: onOpenAyah),
    );
  }

  @override
  State<WReaderBookmarksSheet> createState() => _WReaderBookmarksSheetState();
}

class _WReaderBookmarksSheetState extends State<WReaderBookmarksSheet> {
  late final CBBookmarks _cubit = Modular.get<CBBookmarks>()..load();

  /// Surah lookup (number → metadata) so rows can show the Arabic name.
  Map<int, MSurah> _surahs = const {};

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await Modular.get<DSLocalQuran>().loadSurahs();
    if (!mounted) return;
    setState(() => _surahs = {for (final s in surahs) s.number: s});
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _open(ParamAyahRef ref) {
    Navigator.of(context).pop();
    widget.onOpenAyah(ref);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: context.brand.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocBuilder<CBBookmarks, SBookmarks>(
            bloc: _cubit,
            builder: (context, state) {
              return CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(child: _Header(count: state.all.length)),
                  if (state.status == LoadStatus.loading && state.all.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.w),
                          child: Text(
                            'bookmarks_empty'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.grey16W500,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                      sliver: SliverList.separated(
                        itemCount: state.all.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, i) {
                          final b = state.all[i];
                          final surah = _surahs[b.surah];
                          return _BookmarkRow(
                            color: bookmarkColorFromHex(b.colorHex),
                            title: surah?.arabic.isNotEmpty == true
                                ? surah?.arabic ?? ''
                                : '${'quran_surah_label'.tr()} ${b.surah}',
                            subtitle: '${'quran_ayah_label'.tr()} ${b.ayah}',
                            onTap: () => _open(
                              ParamAyahRef(surah: b.surah, ayah: b.ayah),
                            ),
                            onDelete: () => _cubit.delete(b.id),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.brand.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(
                Icons.bookmark_rounded,
                color: context.brand.primary,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text('bookmarks_title'.tr(), style: AppTextStyles.ink16W700),
              const Spacer(),
              Text('($count)', style: AppTextStyles.grey12W400),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.surfaceMuted,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.bookmark_rounded, color: color, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: context.brand.onSurface,
                      ),
                    ),
                    Text(subtitle, style: AppTextStyles.grey12W400),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: context.brand.muted,
                  size: 20.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
