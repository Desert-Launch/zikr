import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_player.dart';

class SNAdhanPicker extends StatelessWidget {
  const SNAdhanPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBAdhanPlayer>();
    return BlocProvider.value(
      value: cb,
      child: Scaffold(
        appBar: AppBar(
          title: Text('adhan_picker_title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'common_close'.tr(),
              onPressed: cb.stop,
            ),
          ],
        ),
        body: BlocBuilder<CBAdhanPlayer, SAdhanPlayer>(
          builder: (context, state) {
            if (state.allAdhans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              children: [
                _SectionHeader(label: 'adhan_regular_section'.tr()),
                ...state.allAdhans.map((a) => _AdhanRow(
                      adhan: a,
                      selected: state.defaultAdhan?.id == a.id,
                      previewing:
                          state.currentPreview?.id == a.id &&
                              state.status == AdhanPlayerStatus.playing,
                      onTap: () => cb.selectDefault(a.id),
                      onPreview: () => cb.play(a),
                    )),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
                  child: _FajrSwitch(state: state, cubit: cb),
                ),
                if (state.useFajrSpecific) ...[
                  _SectionHeader(label: 'adhan_fajr_section'.tr()),
                  ...state.allAdhans.map((a) => _AdhanRow(
                        adhan: a,
                        selected: state.fajrAdhan?.id == a.id,
                        previewing: state.currentPreview?.id == a.id &&
                            state.status == AdhanPlayerStatus.playing,
                        onTap: () => cb.selectFajr(a.id,
                            useFajrSpecific: state.useFajrSpecific),
                        onPreview: () => cb.play(a),
                        showFajrBadge: a.isFajrDefault,
                      )),
                ],
                SizedBox(height: 16.h),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColorsLight.muted,
        ),
      ),
    );
  }
}

class _FajrSwitch extends StatelessWidget {
  const _FajrSwitch({required this.state, required this.cubit});
  final SAdhanPlayer state;
  final CBAdhanPlayer cubit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: SwitchListTile(
        title: Text('adhan_use_fajr_specific'.tr(),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
        subtitle: Text('adhan_use_fajr_specific_hint'.tr(),
            style: TextStyle(fontSize: 11.sp)),
        value: state.useFajrSpecific,
        onChanged: (v) => cubit.selectFajr(
          state.fajrAdhan?.id,
          useFajrSpecific: v,
        ),
      ),
    );
  }
}

class _AdhanRow extends StatelessWidget {
  const _AdhanRow({
    required this.adhan,
    required this.selected,
    required this.previewing,
    required this.onTap,
    required this.onPreview,
    this.showFajrBadge = false,
  });

  final MAdhan adhan;
  final bool selected;
  final bool previewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final bool showFajrBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColorsLight.primary.withValues(alpha: 0.08)
                : null,
            border: Border.all(
              color: selected
                  ? AppColorsLight.primary
                  : AppColorsLight.border,
              width: selected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColorsLight.primary : AppColorsLight.muted,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(adhan.nameAr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                        if (showFajrBadge)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColorsLight.accent
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text('adhan_fajr_badge'.tr(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColorsLight.accent,
                                )),
                          ),
                      ],
                    ),
                    Text(adhan.muezzinAr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColorsLight.muted,
                        )),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'adhan_preview'.tr(),
                icon: Icon(
                  previewing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_outline_rounded,
                  color: AppColorsLight.primary,
                  size: 28.r,
                ),
                onPressed: previewing
                    ? Modular.get<CBAdhanPlayer>().stop
                    : onPreview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
