import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

class SNHome extends StatefulWidget {
  const SNHome({super.key});

  @override
  State<SNHome> createState() => _SNHomeState();
}

class _SNHomeState extends State<SNHome> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF6F5F2);

  late final CBPrayerTimes _prayerCubit = Modular.get<CBPrayerTimes>();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    Future.microtask(_prayerCubit.refresh);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: BlocProvider.value(
        value: _prayerCubit,
        child: RefreshIndicator(
          color: _green,
          onRefresh: _prayerCubit.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(green: _green)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                sliver: SliverList.list(
                  children: [
                    BlocBuilder<CBPrayerTimes, SPrayerTimes>(
                      builder: (_, state) =>
                          _PrayerCard(state: state, green: _green),
                    ),
                    SizedBox(height: 12.h),
                    _VerseCard(green: _green, gold: _gold),
                    SizedBox(height: 12.h),
                    ..._buildGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGrid() {
    Widget gap() => SizedBox(height: 10.h);

    Widget row(_FeatureCard a, _FeatureCard b) => Row(
      children: [
        Expanded(child: a),
        SizedBox(width: 10.w),
        Expanded(child: b),
      ],
    );

    return [
      // Continue-reading CTA
      _WideCTA(
        icon: Icons.arrow_forward_rounded,
        title: 'home_daily_wird'.tr(),
        subtitle: 'home_daily_wird_hint'.tr(),
        color: _gold,
        route: KhatmaRoutes.fullPlans(),
      ),
      gap(),
      row(
        _FeatureCard(
          icon: Icons.menu_book_rounded,
          title: 'home_mushaf'.tr(),
          subtitle: 'home_mushaf_hint'.tr(),
          color: _green,
          route: RoutesNames.quranBase,
        ),
        _FeatureCard(
          icon: Icons.access_time_rounded,
          title: 'home_adhan'.tr(),
          subtitle: 'home_adhan_hint'.tr(),
          color: _gold,
          route: RoutesNames.prayerBase,
        ),
      ),
      gap(),
      row(
        _FeatureCard(
          icon: Icons.menu_book_outlined,
          title: 'home_azkar'.tr(),
          subtitle: 'home_azkar_hint'.tr(),
          color: _green,
          route: RoutesNames.azkarBase,
        ),
        _FeatureCard(
          icon: Icons.location_on_outlined,
          title: 'home_mosques'.tr(),
          subtitle: 'home_mosques_hint'.tr(),
          color: _gold,
          route: RoutesNames.qiblaBase,
        ),
      ),
      gap(),
      row(
        _FeatureCard(
          icon: Icons.headphones_rounded,
          title: 'home_tasmee'.tr(),
          subtitle: 'home_tasmee_hint'.tr(),
          color: _green,
          route: QuranRoutes.fullReciterPicker(),
        ),
        _FeatureCard(
          icon: Icons.school_outlined,
          title: 'home_tahfeez'.tr(),
          subtitle: 'home_tahfeez_hint'.tr(),
          color: _gold,
          route: RoutesNames.quranBase,
        ),
      ),
      gap(),
      _WideFeature(
        icon: Icons.touch_app_rounded,
        title: 'home_tasbih'.tr(),
        subtitle: 'home_tasbih_hint'.tr(),
        color: _green,
        route: RoutesNames.tasbihBase,
      ),
      gap(),
      _WideFeature(
        icon: Icons.explore_rounded,
        title: 'home_qibla'.tr(),
        subtitle: 'home_qibla_hint'.tr(),
        color: _gold,
        route: RoutesNames.qiblaBase,
      ),
      gap(),
      row(
        _FeatureCard(
          icon: Icons.podcasts_rounded,
          title: 'home_live'.tr(),
          subtitle: 'home_live_hint'.tr(),
          color: _green,
          route: RoutesNames.adhanBase,
        ),
        _FeatureCard(
          icon: Icons.radio_rounded,
          title: 'home_radio'.tr(),
          subtitle: 'home_radio_hint'.tr(),
          color: _gold,
          route: RoutesNames.adhanBase,
        ),
      ),
      gap(),
      row(
        _FeatureCard(
          icon: Icons.notifications_none_rounded,
          title: 'home_reminders'.tr(),
          subtitle: 'home_reminders_hint'.tr(),
          color: _green,
          route: RoutesNames.remindersBase,
        ),
        _FeatureCard(
          icon: Icons.mic_none_rounded,
          title: 'home_podcast'.tr(),
          subtitle: 'home_podcast_hint'.tr(),
          color: _gold,
          route: RoutesNames.adhanBase,
        ),
      ),
      gap(),
      _WideFeature(
        icon: Icons.favorite_border_rounded,
        title: 'home_salawat'.tr(),
        subtitle: 'home_salawat_hint'.tr(),
        color: _gold,
        route: RoutesNames.azkarBase,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.green});

  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128.h,
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 32.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HeaderButton(
              icon: Icons.settings_outlined,
              onTap: () => Modular.to.pushNamed(SettingsRoutes.fullMain()),
            ),
            SizedBox(width: 8.w),
            BlocBuilder<CBAuth, SAuth>(
              bloc: Modular.get<CBAuth>(),
              builder: (_, state) => _HeaderButton(
                icon: Icons.person_outline_rounded,
                onTap: () => Modular.to.pushNamed(
                  state.isLoggedIn
                      ? SettingsRoutes.fullMain()
                      : AuthRoutes.fullLogin(),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'home_page_title'.tr(),
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22.r,
      child: Padding(
        padding: EdgeInsets.all(5.r),
        child: Icon(icon, color: Colors.white, size: 20.r),
      ),
    );
  }
}

/// Per-prayer accent colour + glyph for the chip row.
({Color color, IconData icon}) _prayerStyle(EPrayer prayer) => switch (prayer) {
  EPrayer.fajr => (
    color: const Color(0xFFE2705B),
    icon: Icons.brightness_3_rounded,
  ),
  EPrayer.sunrise => (
    color: const Color(0xFFF2A33C),
    icon: Icons.wb_twilight_rounded,
  ),
  EPrayer.dhuhr => (
    color: const Color(0xFFF2C037),
    icon: Icons.wb_sunny_rounded,
  ),
  EPrayer.asr => (
    color: const Color(0xFF3FA9C4),
    icon: Icons.brightness_6_rounded,
  ),
  EPrayer.maghrib => (
    color: const Color(0xFFE8743B),
    icon: Icons.wb_twilight_outlined,
  ),
  EPrayer.isha => (
    color: const Color(0xFF6C63B5),
    icon: Icons.nightlight_round,
  ),
};

String _prayerLabel(EPrayer prayer) => switch (prayer) {
  EPrayer.fajr => 'prayer_fajr'.tr(),
  EPrayer.sunrise => 'prayer_sunrise'.tr(),
  EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
  EPrayer.asr => 'prayer_asr'.tr(),
  EPrayer.maghrib => 'prayer_maghrib'.tr(),
  EPrayer.isha => 'prayer_isha'.tr(),
};

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.state, required this.green});

  final SPrayerTimes state;
  final Color green;

  @override
  Widget build(BuildContext context) {
    final next = state.nextPrayer;
    final slots = state.slots.isNotEmpty
        ? state.slots
        : [
            EPrayer.fajr,
            EPrayer.sunrise,
            EPrayer.dhuhr,
            EPrayer.asr,
            EPrayer.maghrib,
            EPrayer.isha,
          ].map((p) => PrayerSlot(prayer: p, time: DateTime.now())).toList();

    final caption = StringBuffer('prayer_next_label'.tr());
    if (state.cityName.isNotEmpty) {
      caption
        ..write('  •  ')
        ..write('home_timing'.tr().replaceFirst('{{city}}', state.cityName));
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: TextStyle(
                        color: green,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (_remaining(next).isNotEmpty)
                      Text(
                        _remaining(next),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9.sp,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        caption.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        next == null
                            ? 'prayer_title'.tr()
                            : 'home_next_prayer'.tr().replaceFirst(
                                '{{name}}',
                                _prayerLabel(next.prayer),
                              ),
                        style: TextStyle(
                          color: const Color(0xFF252525),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                CircleAvatar(
                  radius: 19.r,
                  backgroundColor: green,
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 19.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(3.r),
              child: LinearProgressIndicator(
                minHeight: 4.h,
                value: _dayProgress(),
                backgroundColor: const Color(0xFFE9E5DC),
                valueColor: AlwaysStoppedAnimation(green),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: slots
                  .map(
                    (slot) => Expanded(
                      child: _PrayerChip(
                        label: _prayerLabel(slot.prayer),
                        time: state.slots.isEmpty
                            ? '--:--'
                            : DateFormat('HH:mm').format(slot.time),
                        style: _prayerStyle(slot.prayer),
                        active: next?.prayer == slot.prayer,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _remaining(PrayerSlot? next) {
    if (next == null) return '';
    final diff = next.time.difference(DateTime.now());
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) {
      return 'home_remaining_m'.tr().replaceFirst('{{m}}', '$m');
    }
    return 'home_remaining_hm'
        .tr()
        .replaceFirst('{{h}}', '$h')
        .replaceFirst('{{m}}', '$m');
  }

  double _dayProgress() {
    final now = DateTime.now();
    return ((now.hour * 60 + now.minute) / (24 * 60)).clamp(0, 1).toDouble();
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({
    required this.label,
    required this.time,
    required this.style,
    required this.active,
  });

  final String label;
  final String time;
  final ({Color color, IconData icon}) style;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? style.color : style.color.withValues(alpha: 0.14),
          ),
          child: Icon(
            style.icon,
            size: 16.r,
            color: active ? Colors.white : style.color,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 8.5.sp, color: Colors.grey[700]),
        ),
        Text(
          time,
          style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.green, required this.gold});

  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Modular.to.pushNamed(QuranRoutes.readerFromAyah(20, 114)),
      child: Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEBCE78), Color(0xFFC79A33)],
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4DF),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: gold,
                child: Icon(
                  Icons.star_rounded,
                  size: 16.r,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'home_verse_label'.tr(),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: const Color(0xFF9C7B2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'home_verse'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B3A1B),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'home_verse_source'.tr(),
                style: TextStyle(
                  fontSize: 8.5.sp,
                  color: const Color(0xFF9C7B2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square-ish grid tile: icon top-right, title + subtitle bottom, right-aligned.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Modular.to.pushNamed(route),
      child: Container(
        height: 104.h,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 19.r,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 19.r),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width "continue" card: text on the right, action arrow on the left.
class _WideCTA extends StatelessWidget {
  const _WideCTA({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Modular.to.pushNamed(route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20.r),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width feature card: icon on the right, title + subtitle right-aligned.
class _WideFeature extends StatelessWidget {
  const _WideFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Modular.to.pushNamed(route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20.r),
            ),
          ],
        ),
      ),
    );
  }
}
