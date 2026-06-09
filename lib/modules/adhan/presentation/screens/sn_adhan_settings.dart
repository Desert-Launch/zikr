import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';

class SNAdhanSettings extends StatelessWidget {
  const SNAdhanSettings({super.key});

  static const _green = Color(0xFF2F7E63);
  static const _canvas = Color(0xFFFAF9F7);
  static const _border = Color(0xFFE2ECE8);
  static const _prayers = [
    ('fajr', 'prayer_fajr'),
    ('sunrise', 'prayer_sunrise'),
    ('dhuhr', 'prayer_dhuhr'),
    ('asr', 'prayer_asr'),
    ('maghrib', 'prayer_maghrib'),
    ('isha', 'prayer_isha'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBAdhanSettings>();
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: WGradientAppBar(title: 'adhan_alerts_title'.tr()),
        body: BlocBuilder<CBAdhanSettings, SAdhanSettings>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(27.w, 24.h, 27.w, 28.h),
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 9.h),
                  child: Text(
                    'adhan_prayer_alerts_section'.tr(),
                    style: GoogleFonts.tajawal(
                      fontSize: 10.sp,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19.r),
                    border: Border.all(color: _border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19.r),
                    child: Column(
                      children: [
                        for (var i = 0; i < _prayers.length; i++) ...[
                          _PrayerRow(
                            prayerKey: _prayers[i].$1,
                            title: _prayers[i].$2.tr(),
                            state: state,
                            index: i == 0 ? 0 : i - 1,
                            cubit: cubit,
                          ),
                          if (i != _prayers.length - 1)
                            const Divider(height: 1, color: Color(0xFFEDF1EF)),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 76.h),
                const _VirtueCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayerKey,
    required this.title,
    required this.state,
    required this.index,
    required this.cubit,
  });

  final String prayerKey;
  final String title;
  final SAdhanSettings state;
  final int index;
  final CBAdhanSettings cubit;

  bool get isSunrise => prayerKey == 'sunrise';
  bool get enabled =>
      !isSunrise &&
      state.enabled &&
      index < state.notifyForPrayer.length &&
      state.notifyForPrayer[index];

  @override
  Widget build(BuildContext context) {
    final voice = state.voiceNamePerPrayer[prayerKey];
    return InkWell(
      onTap: isSunrise
          ? null
          : () async {
              await Modular.to.pushNamed(AdhanRoutes.voicePicker(prayerKey));
              await cubit.refreshVoice();
            },
      child: SizedBox(
        height: 74.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(22.r),
                onTap: isSunrise
                    ? null
                    : () => cubit.togglePrayer(index, !enabled),
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F4ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    enabled
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_off_outlined,
                    color: enabled
                        ? SNAdhanSettings._green
                        : const Color(0xFF8B8B8B),
                    size: 21.r,
                  ),
                ),
              ),
              SizedBox(width: 13.w),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 14.sp,
                  color: const Color(0xFF303030),
                ),
              ),
              const Spacer(),
              Text(
                isSunrise
                    ? 'adhan_off'.tr()
                    : (voice?.isNotEmpty ?? false)
                    ? voice!
                    : 'adhan_voice_none'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 9.sp,
                  color: const Color(0xFF777777),
                ),
              ),
              if (!isSunrise) ...[
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_left_rounded,
                  color: const Color(0xFF777777),
                  size: 21.r,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 17.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD9B947), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFD9B947),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 22.r),
          ),
          SizedBox(height: 8.h),
          Text(
            'khatma_virtue_title'.tr(),
            style: GoogleFonts.tajawal(
              fontSize: 11.sp,
              color: const Color(0xFF8C7A55),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ وَأَنفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ تِجَارَةً لَّن تَبُورَ',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 13.sp,
              height: 1.8,
              color: const Color(0xFF3E3522),
            ),
          ),
          Text(
            '[فاطر: 29]',
            style: GoogleFonts.tajawal(
              fontSize: 10.sp,
              color: const Color(0xFF8C7A55),
            ),
          ),
        ],
      ),
    );
  }
}
