import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_calc_settings.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_calc_settings.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_check.dart';

/// The calculation-authority picker: "Automatic (recommended)" followed by
/// every method the API reports.
///
/// The list comes from `/v1/methods`, cached — it is not compiled in, so an
/// authority Aladhan adds later shows up here without an app update.
class SNPrayerMethodPicker extends StatefulWidget {
  const SNPrayerMethodPicker({super.key});

  @override
  State<SNPrayerMethodPicker> createState() => _SNPrayerMethodPickerState();
}

class _SNPrayerMethodPickerState extends State<SNPrayerMethodPicker> {
  static const _canvas = Color(0xFFFAF9F7);

  late final CBPrayerCalcSettings _cubit = Modular.get<CBPrayerCalcSettings>();

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBPrayerCalcSettings, SPrayerCalcSettings>(
          builder: (context, state) => Column(
            children: [
              WGradientAppBar(
                title: 'prayer_calc_method'.tr(),
                subtitle: 'prayer_calc_method_picker_subtitle'.tr(),
              ),
              if (state.methodsLoading && state.methods.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(child: _buildList(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(SPrayerCalcSettings state) {
    final automatic = state.settings.mode == ECalculationMode.automatic;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      itemCount: state.methods.length + 1,
      separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFFEDF1EF)),
      itemBuilder: (_, index) {
        if (index == 0) {
          return _Tile(
            title: 'prayer_calc_method_auto'.tr(),
            // Naming what Automatic resolved to is the point of the row: it is
            // the difference between "trust us" and "here is the authority
            // your times come from".
            subtitle: state.resolvedMethodName?.isNotEmpty ?? false
                ? '${'prayer_calc_method_auto_hint'.tr()} · ${state.resolvedMethodName}'
                : 'prayer_calc_method_auto_hint'.tr(),
            selected: automatic,
            onTap: _cubit.useAutomatic,
          );
        }
        final method = state.methods[index - 1];
        return _Tile(
          title: method.name,
          subtitle: method.paramsSummary,
          selected: !automatic && state.settings.manualMethodId == method.id,
          onTap: () => _cubit.useMethod(method.id),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: isTab ? 16 : 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF303030),
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: isTab ? 12.5 : 10.sp,
                color: const Color(0xFF858585),
              ),
            ),
      trailing: WSettingsCheck(selected: selected),
    );
  }
}
