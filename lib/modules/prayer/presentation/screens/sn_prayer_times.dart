import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_header.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_message_view.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_tile.dart';

class SNPrayerTimes extends StatefulWidget {
  const SNPrayerTimes({super.key});

  @override
  State<SNPrayerTimes> createState() => _SNPrayerTimesState();
}

class _SNPrayerTimesState extends State<SNPrayerTimes> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBPrayerTimes _cubit = Modular.get<CBPrayerTimes>();
  late final BoxPrayerSettings _settingsBox = Modular.get<BoxPrayerSettings>();
  late final MPrayerSettings _settings = _settingsBox.current();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBPrayerTimes, SPrayerTimes>(
          builder: (context, state) => RefreshIndicator(
            color: _green,
            onRefresh: _cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: WPrayerHeader(
                    state: state,
                    green: _green,
                    onRefresh: _cubit.refresh,
                  ),
                ),
                if (state.slots.isEmpty &&
                    state.status == PrayerLoadStatus.loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.slots.isEmpty &&
                    state.status == PrayerLoadStatus.permissionDenied)
                  SliverFillRemaining(
                    child: WPrayerMessageView(
                      icon: Icons.location_off_rounded,
                      title: 'prayer_permission_title'.tr(),
                      message: state.error ?? 'prayer_permission_body'.tr(),
                      onRetry: _cubit.refresh,
                    ),
                  )
                else if (state.slots.isEmpty &&
                    state.status == PrayerLoadStatus.error)
                  SliverFillRemaining(
                    child: WPrayerMessageView(
                      icon: Icons.error_outline_rounded,
                      title: 'common_error'.tr(),
                      message: state.error ?? 'common_error'.tr(),
                      onRetry: _cubit.refresh,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                    sliver: SliverList.separated(
                      itemCount: state.slots.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (_, index) {
                        final slot = state.slots[index];
                        return WPrayerTile(
                          slot: slot,
                          isNext: state.nextPrayer?.prayer == slot.prayer,
                          notificationEnabled: _notificationEnabled(
                            slot.prayer,
                          ),
                          green: _green,
                          gold: _gold,
                          onNotificationChanged: slot.prayer.isSalah
                              ? (value) => _setNotification(slot.prayer, value)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _notificationEnabled(EPrayer prayer) {
    final index = _notificationIndex(prayer);
    if (index == null || index >= _settings.notifyForPrayer.length) {
      return false;
    }
    return _settings.notifyForPrayer[index];
  }

  Future<void> _setNotification(EPrayer prayer, bool value) async {
    final index = _notificationIndex(prayer);
    if (index == null) return;
    final notifications = [..._settings.notifyForPrayer];
    while (notifications.length < 5) {
      notifications.add(true);
    }
    notifications[index] = value;
    _settings.notifyForPrayer = notifications;
    await _settingsBox.save(_settings);
    // Rebuild the rolling adhan window so the toggle takes effect immediately.
    unawaited(Modular.get<AdhanScheduler>().reschedule());
    if (mounted) setState(() {});
  }

  int? _notificationIndex(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => 0,
    EPrayer.dhuhr => 1,
    EPrayer.asr => 2,
    EPrayer.maghrib => 3,
    EPrayer.isha => 4,
    EPrayer.sunrise => null,
  };
}
