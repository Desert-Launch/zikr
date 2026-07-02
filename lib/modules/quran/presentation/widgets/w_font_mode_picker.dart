import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';
import 'package:quran/modules/quran/presentation/widgets/w_tajweed_legend_sheet.dart';

/// Reader font-mode picker: Standard Mushaf (V2) vs Tajweed coloured. Reacts to
/// and writes the shared [CBReaderSettings] singleton, so changing the mode
/// re-renders an open Mushaf reader. When Tajweed is active it also surfaces a
/// link to the colour legend.
class WFontModePicker extends StatelessWidget {
  const WFontModePicker({super.key});

  static const _options = <(EQuranFontMode, String, String)>[
    (EQuranFontMode.plainV2, 'quran_font_mode_plain', 'Standard Mushaf'),
    (EQuranFontMode.tajweedV4, 'quran_font_mode_tajweed', 'Tajweed (coloured)'),
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
                for (final (mode, key, fallback) in _options)
                  _ModeRow(
                    label: _t(key, fallback),
                    selected: state.fontMode == mode,
                    onTap: () => cubit.setFontMode(mode),
                  ),
                if (state.fontMode == EQuranFontMode.tajweedV4) ...[
                  Divider(height: 1, color: brand.border),
                  InkWell(
                    onTap: () => WTajweedLegendSheet.show(context),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 13.h),
                      child: Row(
                        children: [
                          Icon(Icons.palette_outlined, color: brand.primary, size: 22.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _t('quran_tajweed_legend_title', 'Tajweed colour guide'),
                              style: AppTextStyles.ink14W500,
                            ),
                          ),
                          WLocalizeRotation(
                            reverse: true,
                            child: Icon(Icons.chevron_left_rounded, color: brand.muted, size: 22.r),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.label, required this.selected, required this.onTap});

  final String label;
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
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? brand.primary : brand.muted,
              size: 22.r,
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: AppTextStyles.ink16W500)),
          ],
        ),
      ),
    );
  }
}
