import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_check.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_note.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_switch.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_salawat.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

/// Bottom sheet that configures the salawat-upon-the-Prophet reminder:
/// a master toggle, a preview of the reminder clip, plus a frequency choice
/// (every 1/2/3 hours, or a single specific time). Interval reminders fire
/// within 08:00–22:00; a specific time is taken exactly as picked, at any hour.
///
/// Built from the shared settings primitives so it matches [SNSettings], which
/// opens this sheet directly instead of carrying its own copy of the controls.
class WSalawatReminderSheet extends StatelessWidget {
  const WSalawatReminderSheet({required this.cubit, super.key});

  final CBSalawat cubit;

  static const _canvas = Color(0xFFFAF9F7);

  /// Frequency options. `0` is the "specific time" sentinel.
  static const _intervals = [1, 2, 3, 0];

  /// Opens the sheet for [cubit].
  ///
  /// Height is capped rather than left to the content: with the reminder on,
  /// the sections are tall enough to fill an `isScrollControlled` sheet edge to
  /// edge, which left no barrier to tap and no non-scrolling area to drag — the
  /// sheet became impossible to dismiss. The cap keeps the barrier reachable,
  /// and the header carries an explicit close button besides.
  static Future<void> show(BuildContext context, CBSalawat cubit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _canvas,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => WSalawatReminderSheet(cubit: cubit),
      // A preview left playing shouldn't outlive the sheet that started it.
    ).whenComplete(cubit.stopPreview);
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return BlocProvider.value(
      value: cubit,
      child: Directionality(
        // Explicit extension — `localize_and_translate` also defines `isRTL`
        // on BuildContext, and importing the app extension makes it ambiguous.
        textDirection: ContextExtensions(context).isRTL
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: SafeArea(
          // The header sits OUTSIDE the scroll view: the drag handle and the
          // close button must stay reachable however far the settings below are
          // scrolled, and a handle that scrolls away takes the sheet's only
          // drag-to-dismiss target with it.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              const _DragHandle(),
              SizedBox(height: isTab ? 14 : 18.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 19.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetTitle(text: 'salawat_reminder_title'.tr()),
                    ),
                    const _CloseButton(),
                  ],
                ),
              ),
              SizedBox(height: isTab ? 12 : 15.h),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    19.w,
                    0,
                    19.w,
                    isTab ? 20 : 24.h,
                  ),
                  child: BlocBuilder<CBSalawat, STasbih>(
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WSettingsGroup(
                            children: [
                              WSettingsRow(
                                icon: Icons.notifications_active_outlined,
                                title: 'salawat_reminder_enable'.tr(),
                                subtitle: 'salawat_reminder_enable_hint'.tr(),
                                trailing: WSettingsSwitch(
                                  value: state.reminderEnabled,
                                  onChanged: (value) => _setEnabled(value),
                                ),
                                onTap: () =>
                                    _setEnabled(!state.reminderEnabled),
                              ),
                              // Outside the `reminderEnabled` branch on
                              // purpose: hearing the clip is how you decide
                              // whether to turn the reminder on at all.
                              WSettingsRow(
                                icon: Icons.graphic_eq_rounded,
                                title: 'salawat_preview_sound'.tr(),
                                subtitle: 'salawat_preview_sound_hint'.tr(),
                                showChevron: false,
                                trailing: _PreviewButton(
                                  playing: state.previewPlaying,
                                ),
                                onTap: cubit.togglePreview,
                              ),
                            ],
                          ),
                          if (state.reminderEnabled) ...[
                            SizedBox(height: isTab ? 12 : 15.h),
                            WSettingsSectionLabel(
                              'salawat_reminder_frequency'.tr(),
                            ),
                            WSettingsGroup(
                              children: [
                                for (final value in _intervals)
                                  WSettingsRow(
                                    icon: value == 0
                                        ? Icons.alarm_rounded
                                        : Icons.schedule_rounded,
                                    title: _labelFor(value),
                                    trailing: WSettingsCheck(
                                      selected: _isSelected(state, value),
                                    ),
                                    onTap: () => _select(state, value),
                                  ),
                              ],
                            ),
                            if (state.reminderIsSpecificTime) ...[
                              SizedBox(height: isTab ? 12 : 15.h),
                              WSettingsGroup(
                                children: [
                                  WSettingsRow(
                                    icon: Icons.access_time_rounded,
                                    title: 'salawat_reminder_pick_time'.tr(),
                                    value: TimeOfDay(
                                      hour: state.reminderHour,
                                      minute: state.reminderMinute,
                                    ).format(context),
                                    onTap: () => _pickTime(context, state),
                                  ),
                                ],
                              ),
                              WSettingsNote(
                                'salawat_reminder_specific_hint'.tr(),
                              ),
                            ] else ...[
                              SizedBox(height: isTab ? 12 : 15.h),
                              WSettingsSectionLabel(
                                'salawat_window_section'.tr(),
                              ),
                              WSettingsGroup(
                                children: [
                                  WSettingsRow(
                                    icon: Icons.wb_twilight_rounded,
                                    title: 'salawat_window_start'.tr(),
                                    value: TimeOfDay(
                                      hour: state.windowStartHour,
                                      minute: 0,
                                    ).format(context),
                                    onTap: () => _pickWindow(
                                      context,
                                      state,
                                      start: true,
                                    ),
                                  ),
                                  WSettingsRow(
                                    icon: Icons.bedtime_outlined,
                                    title: 'salawat_window_end'.tr(),
                                    value: TimeOfDay(
                                      hour: state.windowEndHour,
                                      minute: 0,
                                    ).format(context),
                                    onTap: () => _pickWindow(
                                      context,
                                      state,
                                      start: false,
                                    ),
                                  ),
                                ],
                              ),
                              WSettingsNote('salawat_window_hint'.tr()),
                            ],
                            SizedBox(height: isTab ? 12 : 15.h),
                            WSettingsSectionLabel(
                              'salawat_behaviour_section'.tr(),
                            ),
                            WSettingsGroup(
                              children: [
                                WSettingsRow(
                                  icon: Icons.volume_up_outlined,
                                  title: 'salawat_ignore_silent'.tr(),
                                  subtitle:
                                      defaultTargetPlatform ==
                                          TargetPlatform.iOS
                                      ? 'salawat_ignore_silent_hint_ios'.tr()
                                      : 'salawat_ignore_silent_hint'.tr(),
                                  trailing: WSettingsSwitch(
                                    value: state.ignoreSilent,
                                    onChanged: cubit.setIgnoreSilent,
                                  ),
                                  onTap: () => cubit.setIgnoreSilent(
                                    !state.ignoreSilent,
                                  ),
                                ),
                                WSettingsRow(
                                  icon: Icons.phone_in_talk_outlined,
                                  title: 'salawat_pause_on_call'.tr(),
                                  subtitle: 'salawat_pause_on_call_hint'.tr(),
                                  trailing: WSettingsSwitch(
                                    value: state.pauseOnCall,
                                    onChanged: cubit.setPauseOnCall,
                                  ),
                                  onTap: () =>
                                      cubit.setPauseOnCall(!state.pauseOnCall),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enabling needs the notification grant first — a denied prompt leaves the
  /// toggle off rather than persisting a reminder that can never fire.
  Future<void> _setEnabled(bool value) async {
    if (value) {
      final granted = await Modular.get<NotificationsService>()
          .requestPermission();
      if (!granted) return;
    }
    await cubit.setReminderEnabled(value);
  }

  bool _isSelected(STasbih state, int value) {
    return value == 0
        ? state.reminderIsSpecificTime
        : state.reminderIntervalHours == value;
  }

  Future<void> _select(STasbih state, int value) {
    if (value == 0) {
      return cubit.setReminderTime(state.reminderHour, state.reminderMinute);
    }
    return cubit.setReminderInterval(value);
  }

  Future<void> _pickTime(BuildContext context, STasbih state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.reminderHour,
        minute: state.reminderMinute,
      ),
    );
    if (picked == null) return;
    // Honoured exactly. The 08:00–22:00 window belongs to interval mode, which
    // spreads reminders through the day on its own; a specific time is a
    // deliberate choice, so it is not confined to it. Clamping only the hour
    // here (`picked.hour.clamp(8, 22)`) silently turned 02:49 into 08:49 —
    // the minute changed, the hour appeared stuck on 8.
    await cubit.setReminderTime(picked.hour, picked.minute);
  }

  /// Picks one end of the reminder window. Only the hour is kept — both feeds
  /// schedule per hour and choose their own minute to dodge collisions, so
  /// offering minutes would promise a precision neither honours.
  Future<void> _pickWindow(
    BuildContext context,
    STasbih state, {
    required bool start,
  }) async {
    final current = start ? state.windowStartHour : state.windowEndHour;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
    );
    if (picked == null) return;
    await cubit.setReminderWindow(
      start ? picked.hour : state.windowStartHour,
      start ? state.windowEndHour : picked.hour,
    );
  }

  String _labelFor(int value) {
    switch (value) {
      case 1:
        return 'salawat_reminder_every_1h'.tr();
      case 2:
        return 'salawat_reminder_every_2h'.tr();
      case 3:
        return 'salawat_reminder_every_3h'.tr();
      default:
        return 'salawat_reminder_specific'.tr();
    }
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

/// Matches the weight of the gradient app bar's title, so the sheet reads as
/// the same kind of surface as a full settings screen.
class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: context.isTablet ? 19 : 16.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF303030),
          height: 1.2,
        ),
      ),
    );
  }
}

/// Explicit dismiss for the sheet. The barrier and the drag handle both work,
/// but neither is discoverable — and when the content is long enough to scroll,
/// the handle is the only drag target left, so a visible button is the reliable
/// way out.
class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final size = context.isTablet ? 34.0 : 30.r;
    return Semantics(
      button: true,
      label: 'common_close'.tr(),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF1F4ED),
          ),
          child: Icon(
            Icons.close_rounded,
            size: context.isTablet ? 20 : 17.r,
            color: const Color(0xFF2F7E63),
          ),
        ),
      ),
    );
  }
}

/// Play/stop mark for the reminder-clip preview, styled like the other trailing
/// marks in the settings groups.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.playing});

  static const _green = Color(0xFF2F7E63);

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Icon(
      playing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
      color: _green,
      size: context.isTablet ? 28 : 25.r,
    );
  }
}
