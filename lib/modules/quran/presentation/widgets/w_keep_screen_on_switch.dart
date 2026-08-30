import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// Whether the Mushaf holds the display awake while it is open.
///
/// Writes the shared [CBReaderSettings] singleton, so a reader left open behind
/// this screen drops or retakes the hold as soon as the switch moves — no need
/// to reopen it.
class WKeepScreenOnSwitch extends StatelessWidget {
  const WKeepScreenOnSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cubit = Modular.get<CBReaderSettings>();
    return Material(
      color: brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: brand.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: BlocSelector<CBReaderSettings, SReaderSettings, bool>(
          bloc: cubit,
          selector: (s) => s.keepScreenOn,
          builder: (context, enabled) => SwitchListTile.adaptive(
            value: enabled,
            onChanged: cubit.setKeepScreenOn,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: brand.primary,
            secondary: Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brand.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.brightness_high_rounded,
                color: brand.primary,
                size: 24.r,
              ),
            ),
            title: Text(
              'quran_settings_keep_screen_on'.tr(),
              style: AppTextStyles.ink14W500,
            ),
            subtitle: Text(
              'quran_settings_keep_screen_on_hint'.tr(),
              style: AppTextStyles.grey12W400,
            ),
          ),
        ),
      ),
    );
  }
}
