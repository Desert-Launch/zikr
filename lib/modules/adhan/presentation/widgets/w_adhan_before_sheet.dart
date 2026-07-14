import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';

/// Bottom sheet for choosing how many minutes before the adhan the pre-alert
/// fires: a set of preset chips (Off / 5 / 10 / 15 / 20 / 30) plus a custom
/// field for any other value. Selecting a value persists it through
/// [CBAdhanSettings.setPreNotifyMinutes], which reschedules the adhan window
/// so the pre-notifications rebuild with the new offset.
class WAdhanBeforeSheet extends StatefulWidget {
  const WAdhanBeforeSheet({
    required this.prayerKey,
    required this.cubit,
    super.key,
  });

  final String prayerKey;
  final CBAdhanSettings cubit;

  static const _green = Color(0xFF007A58);

  /// Preset minute offsets. `0` is the "off" sentinel.
  static const _presets = [0, 5, 10, 15, 20, 30];

  /// Opens the sheet for [prayerKey] on [cubit].
  static Future<void> show(
    BuildContext context,
    String prayerKey,
    CBAdhanSettings cubit,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => WAdhanBeforeSheet(prayerKey: prayerKey, cubit: cubit),
    );
  }

  @override
  State<WAdhanBeforeSheet> createState() => _WAdhanBeforeSheetState();
}

class _WAdhanBeforeSheetState extends State<WAdhanBeforeSheet> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _apply(int minutes) async {
    await widget.cubit.setPreNotifyMinutes(widget.prayerKey, minutes);
    if (mounted) Navigator.of(context).pop();
  }

  void _applyCustom() {
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed == null) return;
    // Clamp to a sane window: a pre-alert can't precede the adhan by more than
    // an hour, and 0 falls back to "off".
    _apply(parsed.clamp(0, 60));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: BlocBuilder<CBAdhanSettings, SAdhanSettings>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: WAdhanBeforeSheet._green,
                          size: 22.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'adhan_before_alert'.tr(),
                            style: AppTextStyles.ink16W500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'adhan_before_sheet_hint'.tr(),
                      style: AppTextStyles.grey12W400,
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: WAdhanBeforeSheet._presets.map((value) {
                        final current =
                            state.preNotifyMinutesPerPrayer[widget.prayerKey] ??
                            0;
                        final selected = current == value;
                        return ChoiceChip(
                          label: Text(_labelFor(value)),
                          selected: selected,
                          selectedColor: WAdhanBeforeSheet._green,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontSize: 13.sp,
                          ),
                          backgroundColor: const Color(0xFFF1F0EC),
                          showCheckmark: false,
                          onSelected: (_) => _apply(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'adhan_before_custom'.tr(),
                      style: AppTextStyles.ink14W700,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              hintText: 'adhan_before_custom_hint'.tr(),
                              hintStyle: AppTextStyles.grey12W400,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2ECE8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: WAdhanBeforeSheet._green,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _applyCustom(),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton(
                          onPressed: _applyCustom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WAdhanBeforeSheet._green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 14.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text('common_done'.tr()),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(int value) => value == 0
      ? 'adhan_off'.tr()
      : 'adhan_prenotify_minutes'.tr().replaceFirst('{{m}}', '$value');
}
