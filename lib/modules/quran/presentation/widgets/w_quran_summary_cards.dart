import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_summary_card.dart';

class WQuranSummaryCards extends StatelessWidget {
  const WQuranSummaryCards({
    super.key,
    required this.surahs,
    required this.ayat,
    required this.bookmarks,
    required this.green,
    required this.gold,
    required this.onBookmarks,
  });

  final int surahs;
  final int ayat;
  final int bookmarks;
  final Color green;
  final Color gold;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
      child: Row(
        children: [
          WQuranSummaryCard(
            icon: Icons.bookmark_border_rounded,
            value: '$bookmarks',
            label: 'bookmarks_title'.tr(),
            color: green,
            onTap: onBookmarks,
          ),
          SizedBox(width: 8.w),
          WQuranSummaryCard(
            icon: Icons.star_border_rounded,
            value: '$ayat',
            label: 'quran_ayah_label'.tr(),
            color: gold,
          ),
          SizedBox(width: 8.w),
          WQuranSummaryCard(
            icon: Icons.menu_book_outlined,
            value: '$surahs',
            label: 'quran_surah_label'.tr(),
            color: green,
          ),
        ],
      ),
    );
  }
}
