import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_tune_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_note.dart';

/// Per-timing minute corrections, for a mosque that runs a couple of minutes
/// off the calculation.
///
/// Advanced by design: nothing sends the user here, every value starts at zero,
/// and while they are all zero the app sends no `tune` parameter at all.
class SNPrayerAdjustments extends StatelessWidget {
  const SNPrayerAdjustments({super.key});

  static const _canvas = Color(0xFFFAF9F7);

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBPrayerCalcSettings>();
    final isTab = context.isTablet;
    return BlocProvider.value(
      value: cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBPrayerCalcSettings, SPrayerCalcSettings>(
          builder: (context, state) {
            final tune = state.settings.adjustments;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: WGradientAppBar(
                    title: 'prayer_calc_tune'.tr(),
                    subtitle: 'prayer_calc_tune_subtitle'.tr(),
                    actions: [
                      if (!tune.isZero)
                        IconButton(
                          tooltip: 'prayer_calc_tune_reset'.tr(),
                          onPressed: cubit.resetAdjustments,
                          icon: const Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    19.w,
                    isTab ? 14 : 18.h,
                    19.w,
                    isTab ? 20 : 28.h,
                  ),
                  sliver: SliverList.list(
                    children: [
                      WSettingsGroup(
                        children: [
                          for (final row in _rows(tune))
                            WPrayerTuneRow(
                              label: row.$1.tr(),
                              minutes: row.$2,
                              onChanged: (value) =>
                                  cubit.setAdjustments(row.$3(value)),
                            ),
                        ],
                      ),
                      SizedBox(height: isTab ? 10 : 12.h),
                      WSettingsNote('prayer_calc_tune_note'.tr()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Label key, current value, and how to apply a new one — in the order the
  /// timings occur, not the order the API's `tune` parameter uses (that
  /// ordering is the query builder's problem, not the user's).
  List<(String, int, EPrayerAdjustments Function(int))> _rows(
    EPrayerAdjustments tune,
  ) => [
    ('prayer_imsak', tune.imsak, (v) => tune.copyWith(imsak: v)),
    ('prayer_fajr', tune.fajr, (v) => tune.copyWith(fajr: v)),
    ('prayer_sunrise', tune.sunrise, (v) => tune.copyWith(sunrise: v)),
    ('prayer_dhuhr', tune.dhuhr, (v) => tune.copyWith(dhuhr: v)),
    ('prayer_asr', tune.asr, (v) => tune.copyWith(asr: v)),
    ('prayer_maghrib', tune.maghrib, (v) => tune.copyWith(maghrib: v)),
    ('prayer_sunset', tune.sunset, (v) => tune.copyWith(sunset: v)),
    ('prayer_isha', tune.isha, (v) => tune.copyWith(isha: v)),
    ('prayer_midnight', tune.midnight, (v) => tune.copyWith(midnight: v)),
  ];
}
