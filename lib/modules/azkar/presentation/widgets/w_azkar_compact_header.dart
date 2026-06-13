import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_stat_card.dart';

/// The shorter green header used by the azkar player, with a compact stats row.
class WAzkarCompactHeader extends StatelessWidget {
  const WAzkarCompactHeader({
    super.key,
    required this.itemCount,
    required this.completed,
    required this.favorites,
    required this.green,
    required this.onBack,
  });

  final int itemCount;
  final int completed;
  final int favorites;
  final Color green;
  final VoidCallback onBack;

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
                  onPressed: onBack,
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
                Expanded(
                  child: WAzkarStatCard(value: favorites, label: 'azkar_favorites'.tr(), compact: true),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: WAzkarStatCard(
                    value: completed,
                    label: 'azkar_completed_today'.tr(),
                    compact: true,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: WAzkarStatCard(value: itemCount, label: 'azkar_items_suffix'.tr(), compact: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
