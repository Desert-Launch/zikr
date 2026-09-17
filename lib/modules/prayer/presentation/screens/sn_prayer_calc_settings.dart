import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_choice_sheet.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_note.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';

/// How prayer times are calculated: the authority, the Asr school, the
/// high-latitude rule and the per-prayer minute corrections.
///
/// Deliberately reachable but not prominent — every row here has a correct
/// default, and a user who never opens this screen gets accurate times for
/// wherever they are. It exists for the case the defaults can't cover: a
/// mosque that follows a different authority from the one Aladhan picks.
class SNPrayerCalcSettings extends StatefulWidget {
  const SNPrayerCalcSettings({super.key});

  @override
  State<SNPrayerCalcSettings> createState() => _SNPrayerCalcSettingsState();
}

class _SNPrayerCalcSettingsState extends State<SNPrayerCalcSettings> {
  static const _canvas = Color(0xFFFAF9F7);

  late final CBPrayerCalcSettings _cubit = Modular.get<CBPrayerCalcSettings>();

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBPrayerCalcSettings, SPrayerCalcSettings>(
          builder: (context, state) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WGradientAppBar(
                  title: 'prayer_calc_title'.tr(),
                  subtitle: 'prayer_calc_subtitle'.tr(),
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
                    WSettingsSectionLabel('prayer_calc_method_section'.tr()),
                    WSettingsGroup(
                      children: [
                        WSettingsRow(
                          icon: Icons.public_rounded,
                          title: 'prayer_calc_method'.tr(),
                          subtitle: 'prayer_calc_method_hint'.tr(),
                          value: _methodValue(state),
                          onTap: () => Modular.to.pushNamed(
                            PrayerRoutes.fullMethodPicker(),
                          ),
                        ),
                        WSettingsRow(
                          icon: Icons.wb_twilight_rounded,
                          title: 'prayer_calc_asr'.tr(),
                          subtitle: 'prayer_calc_asr_hint'.tr(),
                          value: state.settings.asrSchool.labelKey.tr(),
                          onTap: () => _pickAsrSchool(context, state),
                        ),
                      ],
                    ),
                    SizedBox(height: isTab ? 12 : 15.h),
                    WSettingsSectionLabel('prayer_calc_advanced_section'.tr()),
                    WSettingsGroup(
                      children: [
                        WSettingsRow(
                          icon: Icons.terrain_rounded,
                          title: 'prayer_calc_highlat'.tr(),
                          subtitle: 'prayer_calc_highlat_hint'.tr(),
                          value: state.settings.highLatitudeRule.labelKey.tr(),
                          onTap: () => _pickHighLatitude(context, state),
                        ),
                        WSettingsRow(
                          icon: Icons.tune_rounded,
                          title: 'prayer_calc_tune'.tr(),
                          subtitle: 'prayer_calc_tune_hint'.tr(),
                          value: state.settings.adjustments.isZero
                              ? 'prayer_calc_tune_none'.tr()
                              : 'prayer_calc_tune_active'.tr(),
                          onTap: () => Modular.to.pushNamed(
                            PrayerRoutes.fullAdjustments(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTab ? 12 : 15.h),
                    WSettingsNote('prayer_calc_note'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The method row's value.
  ///
  /// In automatic mode it names the authority Aladhan actually resolved —
  /// "Automatic · Egyptian General Authority of Survey" — because "Automatic"
  /// on its own answers nothing when the user is comparing against their
  /// mosque. Until a fetch has happened there is nothing to name, so it reads
  /// plain "Automatic".
  String _methodValue(SPrayerCalcSettings state) {
    final name = state.activeMethodName;
    if (state.settings.mode == ECalculationMode.manual) {
      return name.isEmpty ? 'prayer_calc_method_manual'.tr() : name;
    }
    final automatic = 'prayer_calc_method_auto'.tr();
    return name.isEmpty ? automatic : '$automatic · $name';
  }

  Future<void> _pickAsrSchool(
    BuildContext context,
    SPrayerCalcSettings state,
  ) async {
    final choice = await WPrayerChoiceSheet.show<EAsrSchool>(
      context,
      title: 'prayer_calc_asr'.tr(),
      selected: state.settings.asrSchool,
      choices: [
        for (final school in EAsrSchool.values)
          PrayerChoice(
            value: school,
            label: school.labelKey.tr(),
            hint: '${school.labelKey}_hint'.tr(),
          ),
      ],
    );
    if (choice != null) await _cubit.setAsrSchool(choice);
  }

  Future<void> _pickHighLatitude(
    BuildContext context,
    SPrayerCalcSettings state,
  ) async {
    final choice = await WPrayerChoiceSheet.show<EHighLatitudeRule>(
      context,
      title: 'prayer_calc_highlat'.tr(),
      selected: state.settings.highLatitudeRule,
      choices: [
        for (final rule in EHighLatitudeRule.values)
          PrayerChoice(
            value: rule,
            label: rule.labelKey.tr(),
            hint: '${rule.labelKey}_hint'.tr(),
          ),
      ],
    );
    if (choice != null) await _cubit.setHighLatitudeRule(choice);
  }
}
