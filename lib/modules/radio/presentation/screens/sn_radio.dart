import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio_player.dart';
import 'package:quran/modules/radio/presentation/widgets/w_radio_now_playing_bar.dart';
import 'package:quran/modules/radio/presentation/widgets/w_radio_station_tile.dart';

class SNRadio extends StatelessWidget {
  const SNRadio({super.key});

  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF6F5F2);

  /// mp3quran's `?language=` param uses its own codes (e.g. `eng`, not `en`).
  /// Map the active app language onto them; fall back to Arabic.
  static String _apiLanguage() {
    switch (LocalizeAndTranslate.getLanguageCode()) {
      case 'en':
        return 'eng';
      case 'fr':
        return 'fr';
      case 'ur':
        return 'ur';
      case 'ar':
      default:
        return 'ar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _apiLanguage();
    final player = Modular.get<CBRadioPlayer>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<CBRadio>(
          create: (_) => Modular.get<CBRadio>()..load(language: language),
        ),
        BlocProvider<CBRadioPlayer>.value(value: player),
      ],
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        bottomNavigationBar: BlocBuilder<CBRadioPlayer, SRadioPlayer>(
          builder: (_, ps) => WRadioNowPlayingBar(state: ps),
        ),
        body: BlocBuilder<CBRadio, SRadio>(
          builder: (context, state) {
            return RefreshIndicator(
              color: _green,
              onRefresh: () =>
                  BlocProvider.of<CBRadio>(context).refreshLive(language: language),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                SliverToBoxAdapter(
                  child: WGradientAppBar(
                    title: 'radio_title'.tr(),
                    subtitle: 'radio_subtitle'.tr(),
                  ),
                ),
                if (state.status == RadioStatus.error)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: WEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'radio_error'.tr(),
                      subtitle: state.error,
                      isDark: false,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                    sliver: SliverList.list(
                      children: _content(context, state),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, SRadio state) {
    return [
      _SectionHeader(label: 'radio_national_section'.tr()),
      SizedBox(height: 12.h),
      ..._tiles(state.national),
      if (state.live.isNotEmpty || state.liveLoading) ...[
        SizedBox(height: 14.h),
        _SectionHeader(label: 'radio_more_section'.tr()),
        SizedBox(height: 12.h),
        if (state.live.isEmpty && state.liveLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: SizedBox(
                width: 26.w,
                height: 26.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: _green,
                ),
              ),
            ),
          )
        else
          ..._tiles(state.live),
      ],
    ];
  }

  List<Widget> _tiles(List<MRadioStation> stations) {
    return [
      for (final station in stations)
        BlocBuilder<CBRadioPlayer, SRadioPlayer>(
          buildWhen: (a, b) =>
              a.isActive(station.id) != b.isActive(station.id) ||
              (b.isActive(station.id) && a.status != b.status),
          builder: (context, ps) {
            final active = ps.isActive(station.id);
            return WRadioStationTile(
              station: station,
              isActive: active,
              isPlaying: active && ps.isPlaying,
              isLoading: active && ps.isBusy,
              onTap: () => Modular.get<CBRadioPlayer>().toggle(station),
            );
          },
        ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.ink16W700);
  }
}
