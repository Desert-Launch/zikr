import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_audio_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_before_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_group.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_off_row.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_section_label.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_virtue_card.dart';

class SNAdhanPicker extends StatelessWidget {
  const SNAdhanPicker({required this.prayerKey, super.key});

  final String prayerKey;

  static const _canvas = Color(0xFFFAF9F7);

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
                    WAdhanSectionLabel('adhan_before_section'.tr()),
                    WAdhanBeforeRow(state: settingsState, cubit: settings),
                    SizedBox(height: 18.h),
                    WAdhanSectionLabel('adhan_sound_section'.tr()),
                    WAdhanGroup(
                      children: [
                        WAdhanOffRow(
                          selected: !prayerEnabled,
                          onTap: () => settings.togglePrayer(prayerIndex, false),
                        ),
                        for (var i = 0; i < playerState.allAdhans.length; i++)
                          WAdhanAudioRow(
                            adhan: playerState.allAdhans[i],
                            selected: selectedId == playerState.allAdhans[i].id,
                            playing:
                                playerState.currentPreview?.id ==
                                    playerState.allAdhans[i].id &&
                                playerState.status == AdhanPlayerStatus.playing,
                            onSelect: () async {
                              await settings.setPrayerVoice(
                                prayerKey,
                                playerState.allAdhans[i].id,
                              );
                              if (!prayerEnabled) {
                                await settings.togglePrayer(prayerIndex, true);
                              }
                            },
                            onPlay: () => player.play(playerState.allAdhans[i]),
                            onStop: player.stop,
                          ),
                      ],
                    ),
                    SizedBox(height: 76.h),
                    const WAdhanVirtueCard(),
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
