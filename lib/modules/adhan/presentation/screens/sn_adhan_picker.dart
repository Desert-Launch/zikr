import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';

class SNAdhanPicker extends StatelessWidget {
  const SNAdhanPicker({required this.prayerKey, super.key});

  final String prayerKey;

  static const _green = Color(0xFF2F7E63);
  static const _canvas = Color(0xFFFAF9F7);
  static const _border = Color(0xFFE2ECE8);

  @override
  Widget build(BuildContext context) {
    final player = Modular.get<CBAdhanPlayer>();
    final settings = Modular.get<CBAdhanSettings>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: player),
        BlocProvider.value(value: settings),
      ],
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: WGradientAppBar(
          title: 'adhan_prayer_alarm_title'.tr().replaceFirst(
            '{{prayer}}',
            _prayerName(prayerKey),
          ),
          actions: [
            IconButton(
              onPressed: player.stop,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            ),
          ],
        ),
        body: BlocBuilder<CBAdhanPlayer, SAdhanPlayer>(
          builder: (context, playerState) {
            if (playerState.allAdhans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return BlocBuilder<CBAdhanSettings, SAdhanSettings>(
              builder: (context, settingsState) {
                final selectedId =
                    settingsState.voiceIdPerPrayer[prayerKey] ??
                    playerState.defaultAdhan?.id;
                final prayerIndex = _prayerIndex(prayerKey);
                final prayerEnabled =
                    prayerIndex >= 0 &&
                    prayerIndex < settingsState.notifyForPrayer.length &&
                    settingsState.notifyForPrayer[prayerIndex];
                return ListView(
                  padding: EdgeInsets.fromLTRB(27.w, 24.h, 27.w, 28.h),
                  children: [
                    _SectionLabel('adhan_before_section'.tr()),
                    _BeforeAdhanRow(state: settingsState, cubit: settings),
                    SizedBox(height: 18.h),
                    _SectionLabel('adhan_sound_section'.tr()),
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
                            _OffRow(
                              selected: !prayerEnabled,
                              onTap: () =>
                                  settings.togglePrayer(prayerIndex, false),
                            ),
                            const Divider(height: 1, color: Color(0xFFEDF1EF)),
                            for (
                              var i = 0;
                              i < playerState.allAdhans.length;
                              i++
                            ) ...[
                              _AudioRow(
                                adhan: playerState.allAdhans[i],
                                selected:
                                    selectedId == playerState.allAdhans[i].id,
                                playing:
                                    playerState.currentPreview?.id ==
                                        playerState.allAdhans[i].id &&
                                    playerState.status ==
                                        AdhanPlayerStatus.playing,
                                onSelect: () async {
                                  await settings.setPrayerVoice(
                                    prayerKey,
                                    playerState.allAdhans[i].id,
                                  );
                                  if (!prayerEnabled) {
                                    await settings.togglePrayer(
                                      prayerIndex,
                                      true,
                                    );
                                  }
                                },
                                onPlay: () =>
                                    player.play(playerState.allAdhans[i]),
                                onStop: player.stop,
                              ),
                              if (i != playerState.allAdhans.length - 1)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEDF1EF),
                                ),
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
            );
          },
        ),
      ),
    );
  }

  String _prayerName(String key) => switch (key) {
    'fajr' => 'prayer_fajr'.tr(),
    'dhuhr' => 'prayer_dhuhr'.tr(),
    'asr' => 'prayer_asr'.tr(),
    'maghrib' => 'prayer_maghrib'.tr(),
    'isha' => 'prayer_isha'.tr(),
    _ => '',
  };

  int _prayerIndex(String key) => switch (key) {
    'fajr' => 0,
    'dhuhr' => 1,
    'asr' => 2,
    'maghrib' => 3,
    'isha' => 4,
    _ => -1,
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 9.h),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 10.sp,
          color: const Color(0xFF777777),
        ),
      ),
    );
  }
}

class _BeforeAdhanRow extends StatelessWidget {
  const _BeforeAdhanRow({required this.state, required this.cubit});

  final SAdhanSettings state;
  final CBAdhanSettings cubit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(19.r),
      onTap: () {
        final next = switch (state.preNotifyMinutes) {
          0 => 5,
          5 => 10,
          10 => 15,
          _ => 0,
        };
        cubit.setPreNotifyMinutes(next);
      },
      child: Container(
        height: 76.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(color: SNAdhanPicker._border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const _Bell(),
            SizedBox(width: 13.w),
            Text(
              'adhan_before_alert'.tr(),
              style: GoogleFonts.tajawal(
                fontSize: 14.sp,
                color: const Color(0xFF303030),
              ),
            ),
            const Spacer(),
            Text(
              state.preNotifyMinutes == 0
                  ? 'adhan_off'.tr()
                  : 'adhan_prenotify_minutes'.tr().replaceFirst(
                      '{{m}}',
                      '${state.preNotifyMinutes}',
                    ),
              style: GoogleFonts.tajawal(
                fontSize: 9.sp,
                color: const Color(0xFF777777),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: const Color(0xFF777777),
              size: 21.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _OffRow extends StatelessWidget {
  const _OffRow({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              const _Bell(),
              SizedBox(width: 13.w),
              Text(
                'adhan_off'.tr(),
                style: GoogleFonts.tajawal(
                  fontSize: 14.sp,
                  color: const Color(0xFF303030),
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: const Color(0xFF42BE88),
                  size: 22.r,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.adhan,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPlay,
    required this.onStop,
  });

  final MAdhan adhan;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: SizedBox(
        height: 72.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              const _Bell(),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  adhan.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 13.sp,
                    color: selected
                        ? const Color(0xFF42BE88)
                        : const Color(0xFF303030),
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: const Color(0xFF42BE88),
                  size: 22.r,
                ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: playing ? onStop : onPlay,
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: SNAdhanPicker._green,
                  size: 27.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.r,
      height: 42.r,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4ED),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.notifications_none_rounded,
        color: SNAdhanPicker._green,
        size: 21.r,
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
