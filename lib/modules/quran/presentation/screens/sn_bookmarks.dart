import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';

class SNBookmarks extends StatefulWidget {
  const SNBookmarks({super.key});

  @override
  State<SNBookmarks> createState() => _SNBookmarksState();
}

class _SNBookmarksState extends State<SNBookmarks> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBBookmarks _cubit = Modular.get<CBBookmarks>()..load();

  /// Surah lookup (number → metadata) so cards can show the Arabic name and
  /// other details. Loaded once from the cached surah list.
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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(
              title: 'bookmarks_title'.tr(),
              subtitle: 'bookmarks_subtitle'.tr(),
            ),
            Expanded(
              child: BlocBuilder<CBBookmarks, SBookmarks>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading && state.all.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.all.isEmpty) {
                    return _EmptyState();
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    itemCount: state.all.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, i) {
                      final b = state.all[i];
                      return _BookmarkCard(
                        bookmark: b,
                        surah: _surahs[b.surah],
                        onTap: () => Modular.to.pushNamed(
                          QuranRoutes.readerFromAyah(b.surah, b.ayah),
                        ),
                        onDelete: () => _cubit.delete(b.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.brand.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 48.r,
                color: context.brand.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'bookmarks_empty'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.grey16W500,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.surah,
    required this.onTap,
    required this.onDelete,
  });

  final MBookmark bookmark;
  final MSurah? surah;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = bookmarkColorFromHex(bookmark.colorHex);
    final name = surah?.arabic.isNotEmpty == true
        ? surah!.arabic
        : '${'quran_surah_label'.tr()} ${bookmark.surah}';

    return Dismissible(
      key: ValueKey(bookmark.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: context.brand.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26.r,
        ),
      ),
      child: Material(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colour swatch + bookmark icon.
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: accent,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.amiri(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: context.brand.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        children: [
                          _Chip(
                            icon: Icons.menu_book_rounded,
                            label:
                                '${'quran_ayah_label'.tr()} ${bookmark.ayah}',
                          ),
                          if (surah != null)
                            _Chip(
                              icon: surah!.isMakki
                                  ? Icons.brightness_3_rounded
                                  : Icons.location_city_rounded,
                              label: surah!.isMakki
                                  ? 'surah_list_filter_makki'.tr()
                                  : 'surah_list_filter_madani'.tr(),
                            ),
                          if (surah != null)
                            _Chip(
                              icon: Icons.format_list_numbered_rounded,
                              label: 'surah_list_ayah_count'.tr().replaceFirst(
                                '{{count}}',
                                '${surah!.totalAyah}',
                              ),
                            ),
                        ],
                      ),
                      if (bookmark.note != null &&
                          bookmark.note!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          bookmark.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.grey14W400,
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13.r,
                            color: context.brand.muted,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _formatDate(bookmark.createdAt),
                            style: AppTextStyles.grey12W400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: context.brand.muted,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.brand.surfaceMuted,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.r, color: context.brand.muted),
          SizedBox(width: 4.w),
          Text(label, style: AppTextStyles.grey12W500),
        ],
      ),
    );
  }
}
