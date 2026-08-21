import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_ringing.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_ringing.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_ringing_action.dart';

/// In-app full-screen adhan alarm — the FOREGROUND case only.
///
/// When the app is already open at prayer time there's no lockscreen to draw
/// over and no notification worth demoting the moment to, so this screen takes
/// the whole window and plays the full adhan through [CBAdhanRinging].
///
/// The killed / backgrounded cases never reach here: Android shows the native
/// `AdhanAlarmActivity` (which can appear over the lockscreen from a cold
/// process, something Flutter cannot do) and iOS shows an AlarmKit alarm or a
/// critical alert. See `ios/Runner/Adhan/AdhanAlarmChannel.swift` for why iOS
/// has no equivalent of the native Android screen.
class SNAdhanRinging extends StatefulWidget {
  const SNAdhanRinging({required this.prayerKey, super.key});

  final String prayerKey;

  @override
  State<SNAdhanRinging> createState() => _SNAdhanRingingState();
}

class _SNAdhanRingingState extends State<SNAdhanRinging> {
  late final CBAdhanRinging _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBAdhanRinging>()..start(widget.prayerKey);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Leaving the screen must never leave the adhan playing with no visible way
  /// to silence it — every exit route goes through stop().
  Future<void> _dismiss() async {
    await _cubit.stop();
    if (mounted) NavHelper.back();
  }

  Future<void> _openPrayerTimes() async {
    await _cubit.stop();
    if (mounted) Modular.to.navigate(RoutesNames.prayerBase);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CBAdhanRinging>.value(
      value: _cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _dismiss();
        },
        child: WSharedScaffold(
          // The screen's own PopScope above already decides what back means.
          rootBackToHome: false,
          // Black behind the artwork so any letterboxed edge blends into the
          // scrim rather than flashing a green frame.
          backgroundColor: Colors.black,
          withSafeArea: false,
          body: BlocListener<CBAdhanRinging, SAdhanRinging>(
            // Playback finishing on its own dismisses the screen, so the user
            // isn't left staring at a silent alarm.
            listenWhen: (prev, next) => !prev.stopped && next.stopped,
            listener: (_, __) {
              if (mounted) NavHelper.back();
            },
            child: _RingingBody(
              onStop: _dismiss,
              onOpenPrayerTimes: _openPrayerTimes,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingingBody extends StatelessWidget {
  const _RingingBody({required this.onStop, required this.onOpenPrayerTimes});

  final VoidCallback onStop;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.images.adhanBackgroundImage.path),
          fit: BoxFit.cover,
          // Black at 62%, matching the native AdhanAlarmActivity's scrim
          // (res/layout/activity_adhan_alarm.xml) so the in-app and
          // over-the-lockscreen adhan screens are the same screen to the user.
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.62),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _RingingHeader(),
              SizedBox(height: 48.h),
              _RingingActions(
                onStop: onStop,
                onOpenPrayerTimes: onOpenPrayerTimes,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingingHeader extends StatelessWidget {
  const _RingingHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAdhanRinging, SAdhanRinging>(
      buildWhen: (prev, next) =>
          prev.prayerKey != next.prayerKey ||
          prev.voiceNameAr != next.voiceNameAr ||
          prev.startedAt != next.startedAt,
      builder: (_, state) {
        final started = state.startedAt;
        return Column(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 64.sp,
            ),
            SizedBox(height: 20.h),
            if (started != null)
              Text(
                '${started.hour.toString().padLeft(2, '0')}:'
                '${started.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),
            SizedBox(height: 10.h),
            Text(
              'adhan_alarm_now'.tr().replaceFirst(
                '{{prayer}}',
                'prayer_${state.prayerKey}'.tr(),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (state.voiceNameAr.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                state.voiceNameAr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RingingActions extends StatelessWidget {
  const _RingingActions({
    required this.onStop,
    required this.onOpenPrayerTimes,
  });

  final VoidCallback onStop;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WAdhanRingingAction(
          label: 'adhan_stop'.tr(),
          icon: Icons.stop_rounded,
          filled: true,
          onTap: onStop,
        ),
        SizedBox(height: 14.h),
        WAdhanRingingAction(
          label: 'adhan_alarm_open'.tr(),
          icon: Icons.access_time_rounded,
          onTap: onOpenPrayerTimes,
        ),
      ],
    );
  }
}
