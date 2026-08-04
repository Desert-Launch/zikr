import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';

/// Mushaf text-size control: a slider over the persisted `font_scale` range with
/// a live basmala preview that resizes as you drag. Writes the shared
/// [CBReaderSettings] singleton, so an open reader rescales instantly and the
/// value survives a restart.
///
/// The preview uses Amiri rather than the QPC page font — the page fonts are
/// registered per-page and carry PUA glyph codepoints, so they can't render a
/// standalone sample.
class WTextSizeSlider extends StatelessWidget {
  const WTextSizeSlider({super.key});

  static const String _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cubit = Modular.get<CBReaderSettings>();
    return BlocBuilder<CBReaderSettings, SReaderSettings>(
      bloc: cubit,
      builder: (context, state) {
        final scale = state.fontScale;
        return Material(
          color: brand.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: brand.border),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: Column(
              children: [
                // Live preview — clipped so a large scale can't overflow the card.
                ClipRect(
                  child: SizedBox(
                    height: 56.h,
                    child: Center(
                      child: Text(
                        _basmala,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.amiri(
                          fontSize: 22.sp * scale,
                          color: brand.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text('A', style: AppTextStyles.grey12W400),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: brand.primary,
                          thumbColor: brand.primary,
                          inactiveTrackColor: brand.border,
                          overlayColor: brand.primary.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: scale.clamp(
                            CBReaderSettings.minScale,
                            CBReaderSettings.maxScale,
                          ),
                          min: CBReaderSettings.minScale,
                          max: CBReaderSettings.maxScale,
                          divisions: CBReaderSettings.scaleDivisions,
                          label: '${(scale * 100).round()}%',
                          onChanged: cubit.setFontScale,
                        ),
                      ),
                    ),
                    Text(
                      'A',
                      style: AppTextStyles.ink16W500.copyWith(fontSize: 20.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
