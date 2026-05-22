import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_row.dart';

class SNPrayerTimes extends StatefulWidget {
  const SNPrayerTimes({super.key});

  @override
  State<SNPrayerTimes> createState() => _SNPrayerTimesState();
}

class _SNPrayerTimesState extends State<SNPrayerTimes> {
  late final CBPrayerTimes _cubit = Modular.get<CBPrayerTimes>();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1Hz ticker so the countdown to next prayer ticks down live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Stay on cache for the first paint; refresh in the background.
    Future.microtask(_cubit.refresh);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text('prayer_title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _cubit.refresh,
            ),
          ],
        ),
        body: BlocBuilder<CBPrayerTimes, SPrayerTimes>(
          builder: (context, state) {
            if (state.slots.isEmpty &&
                state.status == PrayerLoadStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.slots.isEmpty &&
                state.status == PrayerLoadStatus.permissionDenied) {
              return _PermissionDenied(onRetry: _cubit.refresh, error: state.error);
            }
            if (state.slots.isEmpty &&
                state.status == PrayerLoadStatus.error) {
              return _ErrorView(onRetry: _cubit.refresh, error: state.error);
            }
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
              children: [
                _NextPrayerCard(state: state),
                SizedBox(height: 16.h),
                ...state.slots.map((s) => WPrayerRow(
                      slot: s,
                      isNext: state.nextPrayer?.prayer == s.prayer,
                      isCurrent: state.currentSalah?.prayer == s.prayer,
                      labelAr: _labelAr(s.prayer),
                    )),
                SizedBox(height: 12.h),
                if (state.cityName.isNotEmpty || state.latitude != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      state.cityName.isNotEmpty
                          ? state.cityName
                          : '${state.latitude!.toStringAsFixed(3)}, '
                              '${state.longitude!.toStringAsFixed(3)}',
                      style: TextStyle(
                          fontSize: 11.sp, color: context.brand.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _labelAr(EPrayer p) => switch (p) {
        EPrayer.fajr => 'prayer_fajr'.tr(),
        EPrayer.sunrise => 'prayer_sunrise'.tr(),
        EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
        EPrayer.asr => 'prayer_asr'.tr(),
        EPrayer.maghrib => 'prayer_maghrib'.tr(),
        EPrayer.isha => 'prayer_isha'.tr(),
      };
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.state});
  final SPrayerTimes state;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final next = state.nextPrayer;
    if (next == null) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          'prayer_all_done_today'.tr(),
          style: TextStyle(
              color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      );
    }
    final remaining = next.time.difference(DateTime.now());
    final prayerLabel = switch (next.prayer) {
      EPrayer.fajr => 'prayer_fajr'.tr(),
      EPrayer.sunrise => 'prayer_sunrise'.tr(),
      EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
      EPrayer.asr => 'prayer_asr'.tr(),
      EPrayer.maghrib => 'prayer_maghrib'.tr(),
      EPrayer.isha => 'prayer_isha'.tr(),
    };
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text('prayer_next_label'.tr(),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.sp)),
          SizedBox(height: 4.h),
          Text(
            prayerLabel,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _format(remaining),
            style: TextStyle(
              color: AppColorsLight.accent,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry, this.error});
  final VoidCallback onRetry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded,
                size: 64.r, color: context.brand.muted),
            SizedBox(height: 12.h),
            Text('prayer_permission_title'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 6.h),
            Text(
              error ?? 'prayer_permission_body'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text('common_retry'.tr()),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, this.error});
  final VoidCallback onRetry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64.r, color: context.brand.muted),
            SizedBox(height: 12.h),
            Text(error ?? 'common_error'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: context.brand.muted)),
            SizedBox(height: 16.h),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text('common_retry'.tr()),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
