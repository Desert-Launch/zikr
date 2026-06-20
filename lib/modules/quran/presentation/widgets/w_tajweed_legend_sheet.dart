import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Bottom-sheet legend explaining the Tajweed rule colours used by the V4
/// colour font. The hex values are sampled from the bundled font's own CPAL
/// palette (`QCF4001_COLOR`) so the legend matches what renders on the page.
class WTajweedLegendSheet extends StatelessWidget {
  const WTajweedLegendSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
    builder: (_) => const WTajweedLegendSheet(),
  );

  // (colour, AR key, EN fallback) — sampled from the V4 font palette.
  static const List<(Color, String, String)> _items = [
    (Color(0xFFB50000), 'quran_tajweed_madd', 'Obligatory Madd (elongation)'),
    (Color(0xFFFF7B00), 'quran_tajweed_madd_permissible', 'Permissible Madd'),
    (Color(0xFF09B000), 'quran_tajweed_ghunnah', 'Ghunnah (nasalization)'),
    (Color(0xFF3F48E6), 'quran_tajweed_qalqalah', 'Qalqalah (echo)'),
    (Color(0xFF2FADFF), 'quran_tajweed_ikhfa', 'Ikhfa / Idgham'),
    (Color(0xFF2CA4AB), 'quran_tajweed_iqlab', 'Iqlab'),
    (Color(0xFFA5A5A5), 'quran_tajweed_silent', 'Silent letters'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
        child: Directionality(
          textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'quran_tajweed_legend_title'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
              ),
              SizedBox(height: 14.h),
              for (final (color, key, fallback) in _items)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 7.h),
                  child: Row(
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6.r)),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          _label(key, fallback),
                          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF2A2A2A)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(String key, String fallback) {
    final t = key.tr();
    return t == key ? fallback : t;
  }
}
