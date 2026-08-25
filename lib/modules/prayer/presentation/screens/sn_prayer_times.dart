import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';
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

class _SNPrayerTimesState extends State<SNPrayerTimes> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    Future.microtask(_cubit.refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  /// Picks the times up again when the user comes back from the system settings
  /// [CBPrayerTimes.retry] sent them to.
  ///
  /// Without this the screen would still be showing "location is off" after
  /// they had just switched it on, and the retry button would read as broken
  /// for a second time. Guarded on there being nothing to show, so returning to
  /// a screen that already has times never triggers a fetch.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_cubit.state.slots.isNotEmpty) return;
    _cubit.refresh();
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
                  child: WPrayerHeader(state: state, green: _green, onRefresh: _cubit.refresh),
                ),
                if (state.slots.isEmpty && state.status == PrayerLoadStatus.loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.slots.isEmpty && state.status == PrayerLoadStatus.permissionDenied)
                  SliverFillRemaining(
                    child: WPrayerMessageView(
                      icon: Icons.location_off_rounded,
                      title: 'prayer_permission_title'.tr(),
                      // The reason, translated. `state.error` is the raw
                      // English detail the failing layer produced and belongs
                      // in the log, not on screen — rendering it here is what
                      // put "Location services are disabled" under an Arabic
                      // heading.
                      message: (state.locationFailure?.messageKey ?? 'prayer_permission_body').tr(),
                      onRetry: _cubit.retry,
                    ),
                  )
                else if (state.slots.isEmpty && state.status == PrayerLoadStatus.error)
                  SliverFillRemaining(
                    child: WPrayerMessageView(
                      icon: Icons.error_outline_rounded,
                      title: 'common_error'.tr(),
                      message: 'prayer_times_error_body'.tr(),
                      onRetry: _cubit.refresh,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                    sliver: _buildList(state),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders [SPrayerTimes.displaySlots], NOT `slots`.
  ///
  /// `nextPrayer` rolls into the following day once today's isha has gone, so
  /// listing today's timings against it paired the highlighted tile with a
  /// prayer that had already happened — late at night the fajr card counted
  /// down to this morning's fajr and sat at "00:00". `displaySlots` rolls over
  /// with it, so the highlighted tile always holds the timing being counted to.
  Widget _buildList(SPrayerTimes state) {
    final slots = state.displaySlots;
    final windowStart = state.currentWindowStart;
    return SliverList.separated(
      itemCount: slots.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final slot = slots[index];
        return WPrayerTile(
          slot: slot,
          isNext: state.nextPrayer?.prayer == slot.prayer,
          windowStart: windowStart,
          notificationEnabled: _notificationEnabled(slot.prayer),
          green: _green,
          gold: _gold,
          // Every slot gets a switch, sunrise included. It is not a salah and
          // gets no adhan, but it does carry an alert now, and a row that can
          // be turned on has to show that it can.
          onNotificationChanged: (value) => _setNotification(slot.prayer, value),
        );
      },
    );
  }

  bool _notificationEnabled(EPrayer prayer) {
    final index = _notificationIndex(prayer);
    if (index == null || index >= _settings.notifyForPrayer.length) {
      return false;
    }
    return _settings.notifyForPrayer[index];
  }

  /// Flips one prayer's alert.
  ///
  /// Routed through [CBAdhanSettings] rather than writing the box directly.
  /// That cubit is an app-wide singleton holding its own snapshot of these
  /// flags, so a direct write here changed the stored value but left the adhan
  /// settings screen showing the old one — turn sunrise on from this switch and
  /// the other screen still called it off.
  ///
  /// It also carries two things this screen was missing: it turns the master
  /// adhan switch on when a prayer is enabled — without which the scheduler
  /// returns at its `if (!settings.enabled)` gate and the toggle changes
  /// nothing — and it reschedules on its own debounce.
  ///
  /// The list itself needs no padding here: [CBAdhanSettings.togglePrayer]
  /// grows it, and `current()` hands both screens the same Hive instance, so
  /// [_settings] sees the write without being re-read.
  Future<void> _setNotification(EPrayer prayer, bool value) async {
    final index = _notificationIndex(prayer);
    if (index == null) return;
    await Modular.get<CBAdhanSettings>().togglePrayer(index, value);
    if (mounted) setState(() {});
  }

  /// Slot in `notifyForPrayer`. Sunrise follows the five rather than sitting in
  /// clock order — see [MPrayerSettings.notifyForPrayer] for why.
  int? _notificationIndex(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => 0,
    EPrayer.dhuhr => 1,
    EPrayer.asr => 2,
    EPrayer.maghrib => 3,
    EPrayer.isha => 4,
    EPrayer.sunrise => MPrayerSettings.sunriseIndex,
  };
}
