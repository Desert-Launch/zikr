import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// Page-scroll mode picker: sideways paging vs one continuous column.
///
/// Reads and writes the shared [CBReaderSettings] singleton, so switching here
/// re-seats an open Mushaf reader on the page it was already on. Each row
/// carries a hint, because the difference is about *how the Mushaf moves* and a
/// bare label doesn't carry that.
class WReaderScrollModePicker extends StatelessWidget {
  const WReaderScrollModePicker({super.key});

  // (mode, icon, label key, hint key) — order matches [EReaderScrollMode]'s
  // declaration order.
  static const _options = <(EReaderScrollMode, IconData, String, String)>[
    (
      EReaderScrollMode.horizontal,
      Icons.swipe_rounded,
      'quran_settings_scroll_horizontal',
      'quran_settings_scroll_horizontal_hint',
    ),
    (
      EReaderScrollMode.vertical,
      Icons.swap_vert_rounded,
      'quran_settings_scroll_vertical',
      'quran_settings_scroll_vertical_hint',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cubit = Modular.get<CBReaderSettings>();
    return BlocSelector<CBReaderSettings, SReaderSettings, EReaderScrollMode>(
      bloc: cubit,
      selector: (s) => s.scrollMode,
      builder: (context, current) {
        return Material(
          color: brand.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: brand.border),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              children: [
                for (final (mode, icon, labelKey, hintKey) in _options)
                  _ModeRow(
                    icon: icon,
                    label: labelKey.tr(),
                    hint: hintKey.tr(),
                    selected: current == mode,
                    onTap: () => cubit.setScrollMode(mode),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 13.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.r,
              color: selected ? brand.primary : brand.muted,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.ink16W500),
                  SizedBox(height: 2.h),
                  Text(hint, style: AppTextStyles.grey12W400),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? brand.primary : brand.muted,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }
}
