import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

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
      child: Scaffold(
        backgroundColor: _canvas,
        body: BlocBuilder<CBPrayerTimes, SPrayerTimes>(
          builder: (context, state) => RefreshIndicator(
            color: _green,
            onRefresh: _cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PrayerHeader(state: state, green: _green, onRefresh: _cubit.refresh),
                ),
                if (state.slots.isEmpty && state.status == PrayerLoadStatus.loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.slots.isEmpty && state.status == PrayerLoadStatus.permissionDenied)
                  SliverFillRemaining(
                    child: _MessageView(
                      icon: Icons.location_off_rounded,
                      title: 'prayer_permission_title'.tr(),
                      message: state.error ?? 'prayer_permission_body'.tr(),
                      onRetry: _cubit.refresh,
                    ),
                  )
                else if (state.slots.isEmpty && state.status == PrayerLoadStatus.error)
                  SliverFillRemaining(
                    child: _MessageView(
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
                        return _PrayerTile(
                          slot: slot,
                          isNext: state.nextPrayer?.prayer == slot.prayer,
                          isCurrent: state.currentSalah?.prayer == slot.prayer,
                          notificationEnabled: _notificationEnabled(slot.prayer),
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

class _PrayerHeader extends StatelessWidget {
  const _PrayerHeader({required this.state, required this.green, required this.onRefresh});

  final SPrayerTimes state;
  final Color green;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      height: 275.h,
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55.w,
            top: -70.h,
            child: _OutlineCircle(size: 160.r),
          ),
          Positioned(
            left: -55.w,
            bottom: -75.h,
            child: _OutlineCircle(size: 155.r),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Modular.to.pushNamed(SettingsRoutes.fullMain()),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'prayer_title'.tr(),
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'prayer_header_subtitle'.tr(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 9.sp),
                        ),
                      ],
                    ),
                    SizedBox(width: 7.w),
                    IconButton(
                      onPressed: Modular.to.pop,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 7.h),
                InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: onRefresh,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          state.cityName.isNotEmpty ? state.cityName : 'prayer_location_unknown'.tr(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 9.sp),
                        ),
                        SizedBox(width: 5.w),
                        Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.85), size: 14.r),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weekday(now),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 10.sp),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _date(now),
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _hijriDate(now),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 9.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime date) {
    const ar = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return LocalizeAndTranslate.getLanguageCode() == 'ar' ? ar[date.weekday - 1] : en[date.weekday - 1];
  }

  String _date(DateTime date) {
    const arMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = LocalizeAndTranslate.getLanguageCode() == 'ar' ? arMonths[date.month - 1] : enMonths[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  String _hijriDate(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + (12 * a) - 3;
    final julianDay = date.day + ((153 * m + 2) ~/ 5) + (365 * y) + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;

    var l = julianDay - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - (10631 * n) + 354;
    final j = (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) + ((l ~/ 5670) * ((43 * l) ~/ 15238));
    l = l - (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) - ((j ~/ 16) * ((15238 * j) ~/ 43)) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - ((709 * month) ~/ 24);
    final year = (30 * n) + j - 30;

    const arMonths = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    const enMonths = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Shaaban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qidah',
      'Dhu al-Hijjah',
    ];
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final monthName = isArabic ? arMonths[month - 1] : enMonths[month - 1];
    return isArabic ? '$day $monthName $year هـ' : '$day $monthName $year AH';
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.slot,
    required this.isNext,
    required this.isCurrent,
    required this.notificationEnabled,
    required this.green,
    required this.gold,
    required this.onNotificationChanged,
  });

  final PrayerSlot slot;
  final bool isNext;
  final bool isCurrent;
  final bool notificationEnabled;
  final Color green;
  final Color gold;
  final ValueChanged<bool>? onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: isNext ? 13.h : 10.h),
      decoration: BoxDecoration(
        color: isNext ? green : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isNext ? gold : const Color(0xFFF0F0EE), width: isNext ? 1.5 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: isNext ? _nextContent(context) : _normalContent(context),
    );
  }

  Widget _normalContent(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTime(slot.time),
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[700]),
            ),
            if (onNotificationChanged != null)
              Row(
                children: [
                  Icon(Icons.notifications_none_rounded, color: green, size: 14.r),
                  SizedBox(width: 3.w),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch.adaptive(
                      value: notificationEnabled,
                      activeTrackColor: green,
                      onChanged: onNotificationChanged,
                    ),
                  ),
                  Text(
                    notificationEnabled ? 'prayer_notification_on'.tr() : 'prayer_notification_off'.tr(),
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _label(slot.prayer),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              isCurrent ? 'prayer_current_window'.tr() : 'prayer_upcoming'.tr(),
              style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
            ),
          ],
        ),
        SizedBox(width: 10.w),
        _PrayerIcon(prayer: slot.prayer, active: false, green: green),
      ],
    );
  }

  Widget _nextContent(BuildContext context) {
    final remaining = slot.time.difference(DateTime.now());
    final progress = _progressToPrayer(slot.time);
    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(slot.time),
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: Colors.white, size: 14.r),
                    SizedBox(width: 3.w),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch.adaptive(
                        value: notificationEnabled,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        onChanged: onNotificationChanged,
                      ),
                    ),
                    Text(
                      notificationEnabled ? 'prayer_notification_on'.tr() : 'prayer_notification_off'.tr(),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 8.sp),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _label(slot.prayer),
                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${'prayer_after'.tr()} ${_formatDuration(remaining)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.sp),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            _PrayerIcon(prayer: slot.prayer, active: true, green: green),
          ],
        ),
        Divider(color: Colors.white.withValues(alpha: 0.14), height: 14.h),
        Row(
          children: [
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(color: Colors.white, fontSize: 8.sp),
            ),
            const Spacer(),
            Text(
              'prayer_time_remaining'.tr(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 8.sp),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            minHeight: 4.h,
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
    );
  }

  double _progressToPrayer(DateTime target) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final total = target.difference(start).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(start).inSeconds / total).clamp(0, 1).toDouble();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  String _label(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => 'prayer_fajr'.tr(),
    EPrayer.sunrise => 'prayer_sunrise'.tr(),
    EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
    EPrayer.asr => 'prayer_asr'.tr(),
    EPrayer.maghrib => 'prayer_maghrib'.tr(),
    EPrayer.isha => 'prayer_isha'.tr(),
  };

  String _formatTime(DateTime time) => TimeFormat.hm12(time);
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({required this.prayer, required this.active, required this.green});

  final EPrayer prayer;
  final bool active;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.r,
      height: 42.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFF8F7F1),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 7, offset: Offset(0, 3))],
      ),
      child: Text(_emoji(prayer), style: TextStyle(fontSize: 20.sp)),
    );
  }

  String _emoji(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => '🌅',
    EPrayer.sunrise => '☀️',
    EPrayer.dhuhr => '🌤️',
    EPrayer.asr => '🌥️',
    EPrayer.maghrib => '🌇',
    EPrayer.isha => '🌙',
  };
}

class _OutlineCircle extends StatelessWidget {
  const _OutlineCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 4),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.title, required this.message, required this.onRetry});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58.r, color: const Color(0xFF007A58)),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 14.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('common_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
