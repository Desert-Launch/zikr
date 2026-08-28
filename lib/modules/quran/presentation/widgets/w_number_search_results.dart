import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_number_search.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_meta_row.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_page_pill.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_section_header.dart';

/// Results for a purely numeric query: the number read as a page, as a surah,
/// as a juz', and as a hizb — the last broken into its four arba'. The juz' and
/// every rub' show the verse they open on. Sections the number is out of range
/// for are simply absent.
class WNumberSearchResults extends StatelessWidget {
  const WNumberSearchResults({super.key, required this.numbers, this.onJump});

  final ENumberSearch numbers;

  /// When set, tapping a row jumps within the open reader instead of pushing a
  /// new one.
  final void Function(ParamAyahRef? ref, int page)? onJump;

  @override
  Widget build(BuildContext context) {
    final page = numbers.page;
    final surah = numbers.surah;
    final juz = numbers.juz;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final number = isRtl ? arabicDigits(numbers.number) : '${numbers.number}';

    return ListView(
      padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 24.h),
      children: [
        if (page != null) ...[
          WSearchSectionHeader(title: 'search_section_pages'.tr()),
          WSearchMetaRow(
            icon: Icons.description_outlined,
            title: 'search_page_number'.tr().replaceFirst('{{page}}', number),
            subtitle: numbers.pageSurahArabic.isNotEmpty
                ? numbers.pageSurahArabic
                : numbers.pageSurahName,
            onTap: () => _open(null, page),
          ),
        ],
        if (surah != null) ...[
          WSearchSectionHeader(title: 'search_section_surahs'.tr()),
          WSearchMetaRow(
            icon: Icons.auto_stories_outlined,
            leadingBadge: number,
            title: surah.arabic.isNotEmpty ? surah.arabic : surah.name,
            subtitle: isRtl ? surah.name : surah.arabic,
            page: surah.pageStart > 0 ? surah.pageStart : null,
            onTap: () => _open(
              ParamAyahRef(surah: surah.number, ayah: 1),
              surah.pageStart,
            ),
          ),
        ],
        if (juz != null) ...[
          WSearchSectionHeader(title: 'search_section_juz'.tr()),
          _VerseTile(
            title: juz.surahArabic.isEmpty
                ? 'search_juz_number'.tr().replaceFirst('{{juz}}', number)
                : '${'search_juz_number'.tr().replaceFirst('{{juz}}', number)}'
                      ' · ${juz.surahArabic}',
            page: juz.page,
            text: juz.text,
            onTap: () => _open(juz.ref, juz.page),
          ),
        ],
        if (numbers.rubs.isNotEmpty) ...[
          WSearchSectionHeader(title: 'search_section_arba'.tr()),
          for (final rub in numbers.rubs)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _VerseTile(
                title: mushafRubLabel(rub.hizb, rub.quarter),
                page: rub.page,
                text: rub.text,
                onTap: () => _open(rub.ref, rub.page),
              ),
            ),
        ],
      ],
    );
  }

  /// Opens [ref] on [page] — in place when the reader is already showing, as a
  /// fresh reader otherwise. A null [ref] means the hit names a page rather
  /// than a verse, so nothing is highlighted on arrival.
  void _open(ParamAyahRef? ref, int page) {
    final jump = onJump;
    if (jump != null) {
      jump(ref, page);
      return;
    }
    Modular.to.pushNamed(
      ref == null
          ? QuranRoutes.readerFromPage(page)
          : QuranRoutes.readerFromAyah(ref.surah, ref.ayah),
    );
  }
}

/// A division of the mushaf that opens on a known verse — a juz' or one rub' of
/// a hizb: its name, the page it starts on, and the verse printed there.
class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.title,
    required this.page,
    required this.text,
    required this.onTap,
  });

  final String title;
  final int page;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return WSearchCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '۞',
                style: TextStyle(fontSize: 14.sp, color: brand.accent),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: brand.onSurface,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              WSearchPagePill(page: page),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: brand.primary.withValues(alpha: 0.3),
                  width: 2.5.w,
                ),
              ),
            ),
            padding: EdgeInsetsDirectional.only(start: 10.w),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 17.sp,
                  height: 1.8,
                  color: brand.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
