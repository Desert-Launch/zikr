import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/s_daily_verse.dart';

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
  late final CBDailyVerse _verseCubit = Modular.get<CBDailyVerse>();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    Future.microtask(_prayerCubit.refresh);
    Future.microtask(_verseCubit.load);
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
              SliverToBoxAdapter(
                child: _HeaderBanner(green: _green, gold: _gold),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                sliver: SliverList.list(children: _buildGrid()),
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
        route: KhatmaRoutes.fullHome(),
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

/// Full-width green home header with the prayer and verse cards layered over it.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.green, required this.gold});

  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final cardsTop = topInset + 62.h;
    final headerHeight = cardsTop + 320.h;

    // The banner is laid out RTL (title right, icons left, clock right, prayer
    // chips running Fajr through Maghrib right-to-left) to match the design,
    // regardless of the app-wide direction.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D7E5E), Color(0xFF0A6349)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8.h,
            left: 18.w,
            right: 18.w,
            child: SizedBox(
              height: 42.h,
              child: Row(
                children: [
                  Text(
                    'home_page_title'.tr(),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 30.sp, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  BlocBuilder<CBAuth, SAuth>(
                    bloc: Modular.get<CBAuth>(),
                    builder: (_, state) => _HeaderButton(
                      icon: Icons.person_outline_rounded,
                      onTap: () =>
                          Modular.to.pushNamed(state.isLoggedIn ? SettingsRoutes.fullMain() : AuthRoutes.fullLogin()),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _HeaderButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Modular.to.pushNamed(SettingsRoutes.fullMain()),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, cardsTop, 20.w, 0),
            child: Column(
              children: [
                BlocBuilder<CBPrayerTimes, SPrayerTimes>(
                  builder: (_, state) => _PrayerCard(state: state, green: green),
                ),
                SizedBox(height: 16.h),
                _VerseCard(gold: gold),
              ],
            ),
          ),
        ],
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
      radius: 25.r,
      child: Padding(
        padding: EdgeInsets.all(5.r),
        child: Icon(icon, color: Colors.white, size: 25.r),
      ),
    );
  }
}

/// Per-prayer accent colour + glyph for the chip row.
({Color color, IconData icon}) _prayerStyle(EPrayer prayer) => switch (prayer) {
  EPrayer.fajr => (color: const Color(0xFFE2705B), icon: Icons.brightness_3_rounded),
  EPrayer.sunrise => (color: const Color(0xFFF2A33C), icon: Icons.wb_twilight_rounded),
  EPrayer.dhuhr => (color: const Color(0xFFF2C037), icon: Icons.wb_sunny_rounded),
  EPrayer.asr => (color: const Color(0xFF3FA9C4), icon: Icons.brightness_6_rounded),
  EPrayer.maghrib => (color: const Color(0xFFE8743B), icon: Icons.wb_twilight_outlined),
  EPrayer.isha => (color: const Color(0xFF6C63B5), icon: Icons.nightlight_round),
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

  static const _gold = Color(0xFFD6A72C);

  @override
  Widget build(BuildContext context) {
    final next = state.nextPrayer;
    final allSlots = state.slots.isNotEmpty
        ? state.slots
        : [
            EPrayer.fajr,
            EPrayer.sunrise,
            EPrayer.dhuhr,
            EPrayer.asr,
            EPrayer.maghrib,
            EPrayer.isha,
          ].map((p) => PrayerSlot(prayer: p, time: DateTime.now())).toList();
    // Show the five prayers that are not the highlighted "next" one.
    // final excluded = next?.prayer ?? EPrayer.isha;
    final slots = allSlots.toList();

    final caption = StringBuffer('prayer_next_label'.tr());
    if (state.cityName.isNotEmpty) {
      caption
        ..write(' ')
        ..write('home_timing'.tr().replaceFirst('{{city}}', state.cityName));
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: green,
                  child: Icon(Icons.access_time_rounded, color: Colors.white, size: 24.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        next == null
                            ? 'prayer_title'.tr()
                            : 'home_next_prayer'.tr().replaceFirst('{{name}}', _prayerLabel(next.prayer)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xFF252525), fontSize: 20.sp, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      next == null ? TimeFormat.h12Plain(DateTime.now()) : TimeFormat.h12Plain(next.time),
                      style: TextStyle(color: green, fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.0),
                    ),
                    if (_remaining(next).isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(color: green, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _remaining(next),
                            style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _buildProgressBar(),
            SizedBox(height: 18.h),
            Container(height: 1, color: const Color(0xFFEDEAE3)),
            SizedBox(height: 16.h),
            Row(
              children: slots
                  .map(
                    (slot) => Expanded(
                      child: _PrayerChip(
                        label: _prayerLabel(slot.prayer),
                        time: state.slots.isEmpty ? '--:--' : TimeFormat.h12Plain(slot.time),
                        style: _prayerStyle(slot.prayer),
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
    return 'home_remaining_hm'.tr().replaceFirst('{{h}}', '$h').replaceFirst('{{m}}', '$m');
  }

  /// Fraction of the window between the previous salah and the next one that has
  /// already elapsed: (now − prevPrayer) / (nextPrayer − prevPrayer).
  Widget _buildProgressBar() {
    final p = _progress();
    final filled = (p * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 8.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: filled,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [green, _gold],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1000 - filled,
              child: const ColoredBox(color: Color(0xFFEDEAE3)),
            ),
          ],
        ),
      ),
    );
  }

  /// Fraction of the current prayer window that has elapsed:
  /// (now − previous salah) / (next salah − previous salah).
  /// Sunrise is skipped (not prayed) and the window wraps around midnight.
  double _progress() {
    final now = DateTime.now();
    final times = state.slots.where((s) => s.prayer != EPrayer.sunrise).map((s) => s.time).toList()..sort();
    if (times.length < 2) return 0;

    DateTime? prev;
    DateTime? next;
    for (final t in times) {
      if (t.isAfter(now)) {
        next = t;
        break;
      }
      prev = t;
    }
    // Before today's first salah → window opened with yesterday's last one.
    prev ??= times.last.subtract(const Duration(days: 1));
    // After today's last salah → window closes with tomorrow's first one.
    next ??= times.first.add(const Duration(days: 1));

    final total = next.difference(prev).inSeconds;
    if (total <= 0) return 0;
    final elapsed = now.difference(prev).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0).toDouble();
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({required this.label, required this.time, required this.style});

  final String label;
  final String time;
  final ({Color color, IconData icon}) style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: style.color.withValues(alpha: 0.16)),
          child: Icon(style.icon, size: 20.r, color: style.color),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 2.h),
        Text(
          time,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF252525)),
        ),
      ],
    );
  }
}

/// "Verse of the day": a deterministic random ayah pulled from the bundled
/// mushaf, refreshed once per calendar day, with the text flanked by the two
/// decorative ornaments and a surah/ayah caption underneath.
class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.gold});

  final Color gold;

  static const _ink = Color(0xFF4B3A1B);
  static const _caption = Color(0xFF9C7B2E);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBDailyVerse, SDailyVerse>(
      bloc: Modular.get<CBDailyVerse>(),
      builder: (_, state) {
        final verse = state.verse;
        return InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: verse == null
              ? null
              : () => Modular.to.pushNamed(QuranRoutes.readerFromAyah(verse.surahNumber, verse.ayah)),
          child: SizedBox(
            height: 124.h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: gold, width: 1.2),
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
                      ),
                      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 5))],
                    ),
                  ),
                ),
                Positioned(
                  top: 7.h,
                  right: 5.w,
                  child: Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withValues(alpha: 0.13), width: 4.r),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 7.h),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 13.r,
                          backgroundColor: gold,
                          child: Icon(Icons.star_rounded, size: 14.r, color: Colors.white),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'home_verse_label'.tr(),
                          style: TextStyle(fontSize: 8.sp, color: _caption, fontWeight: FontWeight.w600),
                        ),
                        Expanded(child: Center(child: _verseText(verse))),
                        Text(
                          _sourceLabel(verse),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 8.sp, color: _caption),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The verse text wrapped with the start/end ornaments. Falls back to the
  /// bundled sample verse while the daily verse is still loading.
  Widget _verseText(EDailyVerse? verse) {
    final text = verse?.text ?? 'home_verse'.tr();
    WidgetSpan ornament(String asset) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Image.asset(asset, height: 15.sp),
      ),
    );

    return Text.rich(
      TextSpan(
        style: GoogleFonts.amiri(fontSize: 15.sp, fontWeight: FontWeight.w700, color: _ink, height: 1.45),
        children: [
          ornament('assets/images/verse_ornament_end.png'),
          TextSpan(text: text),
          ornament('assets/images/verse_ornament_start.png'),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Surah name + ayah number caption (Arabic-Indic digits in Arabic), or the
  /// bundled sample source while loading.
  String _sourceLabel(EDailyVerse? verse) {
    if (verse == null) return 'home_verse_source'.tr();
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final name = isArabic ? verse.surahArabicName : verse.surahName;
    final ayah = isArabic ? _toArabicDigits(verse.ayah) : '${verse.ayah}';
    return 'home_verse_source_fmt'.tr().replaceFirst('{{surah}}', name).replaceFirst('{{ayah}}', ayah);
  }
}

/// Converts Western digits in [value] to Arabic-Indic glyphs (٠..٩).
String _toArabicDigits(int value) {
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buf = StringBuffer();
  for (final unit in '$value'.codeUnits) {
    buf.write(unit >= 0x30 && unit <= 0x39 ? eastern[unit - 0x30] : unit);
  }
  return buf.toString();
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
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _HomeIconBox(icon: icon, color: color),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        borderRadius: BorderRadius.circular(28.r),
        onTap: () => Modular.to.pushNamed(route),
        child: Container(
          height: 89.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: const Color(0xFFE6EFEC)),
            boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 14, offset: Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  color: Color(0xFFD4A62A),
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 7))],
                ),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30.r),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFF252525), fontSize: 23.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
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
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            _HomeIconBox(icon: icon, color: color),
          ],
        ),
      ),
    );
  }
}

class _HomeIconBox extends StatelessWidget {
  const _HomeIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isGold = color == const Color(0xFFD6A72C);

    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isGold ? const [Color(0xFFD4AF37), Color(0xFFD4AF37)] : const [Color(0xFF0D7E5E), Color(0xFF0A6349)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 7, offset: Offset(0, 3))],
      ),
      child: Icon(icon, color: Colors.white, size: 20.r),
    );
  }
}
