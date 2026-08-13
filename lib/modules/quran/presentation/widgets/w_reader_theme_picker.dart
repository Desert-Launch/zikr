import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme_mode.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// Reading-surface theme picker: Match device, White, Light, Dark. Reacts to
/// and writes the shared [CBReaderSettings] singleton, so changing the theme
/// re-styles an open Mushaf reader instantly. Each row shows a swatch of the
/// actual page colour.
///
/// Selection tracks the user's CHOICE (`themeMode`), not the resolved colour:
/// while "Match device" is selected it stays selected in dark mode too, instead
/// of the tick jumping to "Dark".
class WReaderThemePicker extends StatelessWidget {
  const WReaderThemePicker({super.key});

  // (mode, i18n key, fallback, swatch colour) — swatches mirror
  // `readerBackground` in the Mushaf renderer so the preview matches the real
  // reading surface. Order matches [EReaderThemeMode]'s declaration order.
  // `system` has no fixed colour of its own, so it gets an icon instead (null).
  static const _options = <(EReaderThemeMode, String, String, Color?)>[
    (
      EReaderThemeMode.system,
      'quran_settings_theme_system',
      'Match device',
      null,
    ),
    (
      EReaderThemeMode.white,
      'quran_settings_theme_white',
      'White',
      Colors.white,
    ),
    (
      EReaderThemeMode.light,
      'quran_settings_theme_light',
      'Light',
      AppColors.paperWarm,
    ),
    (
      EReaderThemeMode.dark,
      'quran_settings_theme_dark',
      'Dark',
      AppColors.darkBackground,
    ),
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
                for (final (mode, key, fallback, swatch) in _options)
                  _ThemeRow(
                    label: _t(key, fallback),
                    swatch: swatch,
                    selected: state.themeMode == mode,
                    onTap: () => cubit.setThemeMode(mode),
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

  /// The page colour this row selects, or null for "Match device" — which has
  /// no colour of its own, so it shows an icon in the swatch's place.
  final Color? swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final swatch = this.swatch;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 13.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: swatch == null
                  ? Icon(
                      Icons.brightness_auto_rounded,
                      size: 22.r,
                      color: brand.muted,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(color: brand.border),
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: AppTextStyles.ink16W500)),
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
