import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/quran/domain/entities/e_hizb_entry.dart';
import 'package:quran/modules/quran/domain/entities/e_juz_entry.dart';
import 'package:quran/modules/quran/presentation/widgets/w_star_number.dart';

/// A juz' row in the index. Tapping the header expands it to reveal the two
/// ahzab inside, each navigating to its start page via [onOpenPage].
class WJuzCard extends StatefulWidget {
  const WJuzCard({super.key, required this.entry, required this.green, required this.gold, required this.onOpenPage});

  final EJuzEntry entry;
  final Color green;
  final Color gold;
  final ValueChanged<int> onOpenPage;

  @override
  State<WJuzCard> createState() => _WJuzCardState();
}

class _WJuzCardState extends State<WJuzCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  WStarNumber(number: entry.number, green: widget.green),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'surah_list_juz_n'.tr().replaceFirst('{{juz}}', '${entry.number}'),
                          style: GoogleFonts.amiri(fontSize: 18.sp, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          entry.startSurahArabic,
                          textAlign: TextAlign.end,
                          style: AppTextStyles.grey12W400,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: widget.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'search_page'.tr().replaceFirst('{{page}}', '${entry.startPage}'),
                      style: AppTextStyles.ink12W400.copyWith(color: widget.green, fontSize: 10.sp, height: 1.2),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: widget.green, size: 22.r),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              child: Column(
                children: [
                  Divider(height: 1.h, color: const Color(0xFFEDEFEC)),
                  for (final hizb in entry.hizbs)
                    _WHizbRow(hizb: hizb, gold: widget.gold, onTap: () => widget.onOpenPage(hizb.startPage)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A single hizb line shown under an expanded juz' card.
class _WHizbRow extends StatelessWidget {
  const _WHizbRow({required this.hizb, required this.gold, required this.onTap});

  final EHizbEntry hizb;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 9.h),
        child: Row(
          children: [
            Icon(Icons.bookmark_border_rounded, color: gold, size: 18.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'surah_list_hizb_n'.tr().replaceFirst('{{hizb}}', '${hizb.number}'),
                style: AppTextStyles.ink12W400.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              hizb.startSurahArabic,
              style: AppTextStyles.grey12W400,
            ),
            SizedBox(width: 8.w),
            Text(
              'search_page'.tr().replaceFirst('{{page}}', '${hizb.startPage}'),
              style: AppTextStyles.grey12W400.copyWith(color: gold),
            ),
          ],
        ),
      ),
    );
  }
}
