import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_feature_card.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_header_banner.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_wide_feature.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_daily_verse.dart';

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
                child: WHomeHeaderBanner(green: _green, gold: _gold),
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

    Widget row(WHomeFeatureCard a, WHomeFeatureCard b) => Row(
      children: [
        Expanded(child: a),
        SizedBox(width: 10.w),
        Expanded(child: b),
      ],
    );

    return [
      // Continue-reading CTA
      WHomeWideFeature(
        icon: Assets.icons.arrowRight.path,
        title: 'home_daily_wird'.tr(),
        color: _gold,
        route: KhatmaRoutes.fullHome(),
      ),
      gap(),
      row(
        WHomeFeatureCard(
          icon: Assets.icons.clock.path,
          title: 'home_adhan'.tr(),
          subtitle: 'home_adhan_hint'.tr(),
          color: _gold,
          route: RoutesNames.prayerBase,
        ),
        WHomeFeatureCard(
          icon: Assets.icons.bookClose.path,
          title: 'home_mushaf'.tr(),
          subtitle: 'home_mushaf_hint'.tr(),
          color: _green,
          route: RoutesNames.quranBase,
        ),
      ),
      gap(),
      row(
        WHomeFeatureCard(
          icon: Assets.icons.location.path,
          title: 'home_mosques'.tr(),
          subtitle: 'home_mosques_hint'.tr(),
          color: _gold,
          route: RoutesNames.qiblaBase,
        ),
        WHomeFeatureCard(
          icon: Assets.icons.hand.path,
          title: 'home_azkar'.tr(),
          subtitle: 'home_azkar_hint'.tr(),
          color: _green,
          route: RoutesNames.azkarBase,
        ),
      ),
      gap(),
      row(
        WHomeFeatureCard(
          icon: Assets.icons.bookOpen.path,
          title: 'home_tahfeez'.tr(),
          subtitle: 'home_tahfeez_hint'.tr(),
          color: _gold,
          route: RoutesNames.quranBase,
        ),
        WHomeFeatureCard(
          icon: Assets.icons.microphone.path,
          title: 'home_tasmee'.tr(),
          subtitle: 'home_tasmee_hint'.tr(),
          color: _green,
          route: QuranRoutes.fullReciterPicker(),
        ),
      ),
      gap(),
      WHomeWideFeature(
        icon: Assets.icons.circle.path,
        title: 'home_tasbih'.tr(),
        subtitle: 'home_tasbih_hint'.tr(),
        color: _green,
        route: RoutesNames.tasbihBase,
      ),
      gap(),
      WHomeWideFeature(
        icon: Assets.icons.compass.path,
        title: 'home_qibla'.tr(),
        subtitle: 'home_qibla_hint'.tr(),
        color: _gold,
        route: RoutesNames.qiblaBase,
      ),
      gap(),
      row(
        WHomeFeatureCard(
          icon: Assets.icons.signal.path,
          title: 'home_radio'.tr(),
          subtitle: 'home_radio_hint'.tr(),
          color: _gold,
          route: RoutesNames.adhanBase,
        ),
        WHomeFeatureCard(
          icon: Assets.icons.tv.path,
          title: 'home_live'.tr(),
          subtitle: 'home_live_hint'.tr(),
          color: _green,
          route: RoutesNames.adhanBase,
        ),
      ),
      gap(),
      row(
        WHomeFeatureCard(
          icon: Assets.icons.headphones.path,
          title: 'home_podcast'.tr(),
          subtitle: 'home_podcast_hint'.tr(),
          color: _gold,
          route: RoutesNames.adhanBase,
        ),
        WHomeFeatureCard(
          icon: Assets.icons.bell.path,
          title: 'home_reminders'.tr(),
          subtitle: 'home_reminders_hint'.tr(),
          color: _green,
          route: RoutesNames.remindersBase,
        ),
      ),
      gap(),
      WHomeWideFeature(
        icon: Assets.icons.heart.path,
        title: 'home_salawat'.tr(),
        subtitle: 'home_salawat_hint'.tr(),
        color: _gold,
        route: RoutesNames.azkarBase,
      ),
    ];
  }
}
