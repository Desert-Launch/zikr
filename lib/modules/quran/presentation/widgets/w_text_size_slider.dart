import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';
import 'package:quran/modules/quran/presentation/widgets/w_basmala_line.dart';

/// Mushaf text-size control: a slider over the persisted scale range with a
/// live basmala preview that resizes as you drag. Writes the shared
/// [CBReaderSettings] singleton, so the open reader rescales instantly.
class WTextSizeSlider extends StatefulWidget {
  const WTextSizeSlider({super.key});

  @override
  State<WTextSizeSlider> createState() => _WTextSizeSliderState();
}

class _WTextSizeSliderState extends State<WTextSizeSlider> {
  @override
  void initState() {
    super.initState();
    // Ensure QCF_P1 is registered so the basmala preview renders real glyphs.
    Modular.get<DSQpcFontLoader>().loadPage(1);
  }

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
                        WBasmalaLine.basmalaGlyphs,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontFamily: WBasmalaLine.fontFamily,
                          fontSize: 26.sp * scale,
                          color: brand.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
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
                          value: scale,
                          min: CBReaderSettings.minScale,
                          max: CBReaderSettings.maxScale,
                          divisions: 7,
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
