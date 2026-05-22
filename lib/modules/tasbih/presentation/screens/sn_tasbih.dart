import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

class SNTasbih extends StatelessWidget {
  const SNTasbih({super.key});

  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ',
  ];

  static const _targets = [33, 99, 100, 500, 1000];

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBTasbih>();
    return BlocProvider.value(
      value: cb,
      child: Scaffold(
        appBar: AppBar(
          title: Text('tasbih_title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'tasbih_history'.tr(),
              onPressed: () => Modular.to.pushNamed(TasbihRoutes.fullHistory()),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'tasbih_hourly_title'.tr(),
              onPressed: () => Modular.to.pushNamed(TasbihRoutes.fullHourly()),
            ),
          ],
        ),
        body: BlocBuilder<CBTasbih, STasbih>(
          builder: (context, state) {
            return Column(
              children: [
                SizedBox(height: 12.h),
                _PhraseSelector(value: state.zekrAr, options: _phrases, onChanged: cb.setZekr),
                SizedBox(height: 12.h),
                _TargetSelector(value: state.target, options: _targets, onChanged: cb.setTarget),
                Expanded(child: _CountCircle(state: state, onTap: cb.tap)),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text('tasbih_reset'.tr()),
                          onPressed: cb.reset,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PhraseSelector extends StatelessWidget {
  const _PhraseSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: options.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final opt = options[i];
          final selected = opt == value;
          return ChoiceChip(
            label: Text(opt, style: GoogleFonts.amiri(fontSize: 14.sp)),
            selected: selected,
            onSelected: (_) => onChanged(opt),
            selectedColor: AppColorsLight.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: selected
                  ? AppColorsLight.primary
                  : context.brand.onSurface,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            side: BorderSide(
              color: selected ? AppColorsLight.primary : context.brand.border,
            ),
          );
        },
      ),
    );
  }
}

class _TargetSelector extends StatelessWidget {
  const _TargetSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options
            .map((n) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ChoiceChip(
                    label: Text('$n', style: TextStyle(fontSize: 12.sp)),
                    selected: n == value,
                    onSelected: (_) => onChanged(n),
                    selectedColor: AppColorsLight.accent.withValues(alpha: 0.2),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CountCircle extends StatelessWidget {
  const _CountCircle({required this.state, required this.onTap});
  final STasbih state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 260.r,
          height: 260.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 260.r,
                height: 260.r,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 12.r,
                  backgroundColor: context.brand.border,
                  color: state.isComplete
                      ? AppColorsLight.success
                      : AppColorsLight.primary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.count}',
                    style: TextStyle(
                      fontSize: 72.sp,
                      fontWeight: FontWeight.w900,
                      color: state.isComplete
                          ? AppColorsLight.success
                          : AppColorsLight.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${'tasbih_target_label'.tr()} ${state.target}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.brand.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
