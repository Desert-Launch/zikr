import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_rule.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/widgets/tajweed_palette.dart';

/// Bottom-sheet legend explaining the Tajweed rule colours.
///
/// Colours are pulled from [tajweedColour] for the *active* reader theme
/// (Approach B), so the swatches always match what's rendered on the page —
/// light, sepia, or dark.
class WTajweedLegendSheet extends StatelessWidget {
  const WTajweedLegendSheet({required this.theme, super.key});

  final ReaderTheme theme;

  static Future<void> show(BuildContext context) {
    final theme = Modular.get<CBReaderSettings>().state.theme;
    final dark = theme == ReaderTheme.dark;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => WTajweedLegendSheet(theme: theme),
    );
  }

  // The 7 categories, in legend order, each with an EN fallback label.
  static const List<(ETajweedRule, String)> _items = [
    (ETajweedRule.maddObligatory, 'Obligatory Madd (elongation)'),
    (ETajweedRule.maddPermissible, 'Permissible Madd'),
    (ETajweedRule.ghunnah, 'Ghunnah (nasalization)'),
    (ETajweedRule.qalqalah, 'Qalqalah (echo)'),
    (ETajweedRule.ikhfaIdgham, 'Ikhfa / Idgham'),
    (ETajweedRule.iqlab, 'Iqlab'),
    (ETajweedRule.silent, 'Silent letters'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = theme == ReaderTheme.dark;
    final brightness = tajweedBrightness(theme);
    final titleColour = dark ? Colors.white : const Color(0xFF1A1A1A);
    final labelColour = dark ? Colors.white70 : const Color(0xFF2A2A2A);

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
                    color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'quran_tajweed_legend_title'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: titleColour),
              ),
              SizedBox(height: 14.h),
              for (final (rule, fallback) in _items)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 7.h),
                  child: Row(
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: tajweedColour(rule, brightness: brightness),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          _label(rule.legendKey, fallback),
                          style: TextStyle(fontSize: 15.sp, color: labelColour),
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
