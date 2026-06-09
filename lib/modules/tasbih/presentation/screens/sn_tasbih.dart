import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

class SNTasbih extends StatelessWidget {
  const SNTasbih({super.key});

  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBTasbih>();
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: _canvas,
        body: BlocBuilder<CBTasbih, STasbih>(
          builder: (_, state) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WGradientAppBar(
                  title: 'tasbih_digital_title'.tr(),
                  subtitle: 'tasbih_digital_subtitle'.tr(),
                  actions: [
                    IconButton(
                      onPressed: () =>
                          Modular.to.pushNamed(TasbihRoutes.fullHourly()),
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
                sliver: SliverList.list(
                  children: [
                    _PhraseSelector(
                      selected: state.zekrAr,
                      phrases: _phrases,
                      green: _green,
                      onChanged: cubit.setZekr,
                    ),
                    SizedBox(height: 12.h),
                    _CounterCard(
                      state: state,
                      totalToday: state.count,
                      green: _green,
                      onTap: cubit.tap,
                      onReset: cubit.reset,
                    ),
                    SizedBox(height: 12.h),
                    _VirtueCard(gold: _gold),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseSelector extends StatelessWidget {
  const _PhraseSelector({
    required this.selected,
    required this.phrases,
    required this.green,
    required this.onChanged,
  });

  final String selected;
  final List<String> phrases;
  final Color green;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: phrases.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 2.75,
      ),
      itemBuilder: (_, index) {
        final phrase = phrases[index];
        final active = phrase == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: () => onChanged(phrase),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? green.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: active ? Border.all(color: green) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phrase,
                  style: GoogleFonts.amiri(
                    color: active ? green : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (active)
                  Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.state,
    required this.totalToday,
    required this.green,
    required this.onTap,
    required this.onReset,
  });

  final STasbih state;
  final int totalToday;
  final Color green;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              state.zekrAr,
              style: GoogleFonts.amiri(
                color: green,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 28.h),
            Container(
              width: 126.r,
              height: 126.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.09),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${state.count}',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '${'tasbih_of'.tr()} ${state.target}',
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 42.w,
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 3.h,
                      color: green,
                      backgroundColor: const Color(0xFFE8E7E2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            Divider(color: green.withValues(alpha: 0.16)),
            SizedBox(height: 6.h),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 14),
                  label: Text('tasbih_reset_counter'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: const BorderSide(color: Color(0xFFE3E2DD)),
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    textStyle: TextStyle(fontSize: 9.sp),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalToday',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'tasbih_today_total'.tr(),
                      style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard({required this.gold});

  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -35.h,
            end: -30.w,
            child: Container(
              width: 82.r,
              height: 82.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gold.withValues(alpha: 0.15),
                  width: 3,
                ),
              ),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: 13.r,
                backgroundColor: gold,
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'tasbih_virtue_title'.tr(),
                style: TextStyle(fontSize: 8.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 7.h),
              Text(
                'tasbih_virtue_body'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 12.sp, height: 1.7),
              ),
              SizedBox(height: 5.h),
              Text(
                'tasbih_virtue_source'.tr(),
                style: TextStyle(fontSize: 7.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
