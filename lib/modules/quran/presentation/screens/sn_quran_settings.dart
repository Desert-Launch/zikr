import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/widgets/w_font_mode_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_theme_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_text_size_slider.dart';

/// Quran-specific settings hub, reached from the gear icon on the surah list.
/// Structured to grow — for now it surfaces audio downloads and reciter choice.
class SNQuranSettings extends StatelessWidget {
  const SNQuranSettings({super.key});

  static const _canvas = Color(0xFFF8F7F4);

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            WGradientAppBar(title: 'quran_settings_title'.tr()),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                children: [
                  _SettingsTile(
                    icon: Icons.download_for_offline_rounded,
                    title: 'quran_settings_audio_downloads'.tr(),
                    hint: 'quran_settings_audio_downloads_hint'.tr(),
                    onTap: () => Modular.to.pushNamed(QuranRoutes.fullReciterDownloads()),
                  ),
                  SizedBox(height: 10.h),
                  _SettingsTile(
                    icon: Icons.record_voice_over_rounded,
                    title: 'quran_settings_choose_reciter'.tr(),
                    hint: 'quran_settings_choose_reciter_hint'.tr(),
                    onTap: () => Modular.to.pushNamed(QuranRoutes.fullReciterPicker()),
                  ),
                  SizedBox(height: 22.h),
                  _SectionLabel('quran_settings_font_mode'.tr()),
                  SizedBox(height: 8.h),
                  const WFontModePicker(),
                  SizedBox(height: 22.h),
                  _SectionLabel('quran_settings_reader_theme'.tr()),
                  SizedBox(height: 8.h),
                  const WReaderThemePicker(),
                  SizedBox(height: 22.h),
                  _SectionLabel('quran_settings_text_size'.tr()),
                  SizedBox(height: 8.h),
                  const WTextSizeSlider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.ink12W500),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.hint, required this.onTap});

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Material(
      color: brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: brand.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: brand.primary, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.ink14W500),
                    SizedBox(height: 3.h),
                    Text(hint, style: AppTextStyles.grey12W400),
                  ],
                ),
              ),
              WLocalizeRotation(
                reverse: true,
                child: Icon(Icons.chevron_left_rounded, color: brand.muted, size: 24.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
