import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// Reading-surface theme picker: Light, Sepia, Dark. Reacts to and writes the
/// shared [CBReaderSettings] singleton, so changing the theme re-styles an open
/// Mushaf reader instantly. Each row shows a swatch of the actual page colour.
class WReaderThemePicker extends StatelessWidget {
  const WReaderThemePicker({super.key});

  // (theme, i18n key, fallback, swatch colour) — swatches mirror `_bgFor` in
  // the Mushaf renderer so the preview matches the real reading surface.
  static const _options = <(ReaderTheme, String, String, Color)>[
    (ReaderTheme.light, 'quran_settings_theme_light', 'Light', AppColors.paperWarm),
    (ReaderTheme.sepia, 'quran_settings_theme_sepia', 'Sepia', AppColors.paperCream),
    (ReaderTheme.dark, 'quran_settings_theme_dark', 'Dark', AppColors.darkBackground),
  ];

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cubit = Modular.get<CBReaderSettings>();
    return BlocBuilder<CBReaderSettings, SReaderSettings>(
      bloc: cubit,
      builder: (context, state) {
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
                for (final (theme, key, fallback, swatch) in _options)
                  _ThemeRow(
                    label: _t(key, fallback),
                    swatch: swatch,
                    selected: state.theme == theme,
                    onTap: () => cubit.setTheme(theme),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _t(String key, String fallback) {
    final v = key.tr();
    return v == key ? fallback : v;
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color swatch;
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
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: brand.border),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: AppTextStyles.ink16W500)),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? brand.primary : brand.muted,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }
}
