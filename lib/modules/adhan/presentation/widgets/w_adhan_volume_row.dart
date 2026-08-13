import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// Adhan-loudness slider row (0–100).
///
/// Deliberately NOT a [WAdhanSettingRow] with a slider in its `trailing` slot:
/// a slider needs the full row width to be draggable, and that slot is sized
/// for a switch.
///
/// The drag is previewed locally and only [onChanged] on release commits it.
/// Committing per-frame would persist to Hive and re-arm the whole adhan window
/// on every pixel of movement — on Android the level is baked into each armed
/// alarm, so a commit is a real reschedule, not a cheap write.
class WAdhanVolumeRow extends StatefulWidget {
  const WAdhanVolumeRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  /// Persisted level, 0–100. Also the value the local preview resets to when
  /// the setting changes from elsewhere.
  final int value;

  /// Called once per gesture, on release — never mid-drag.
  final ValueChanged<int> onChanged;

  /// Platform caveat shown under the title (iOS can only scale in-app audio).
  final String? hint;

  @override
  State<WAdhanVolumeRow> createState() => _WAdhanVolumeRowState();
}

class _WAdhanVolumeRowState extends State<WAdhanVolumeRow> {
  static const _green = Color(0xFF2F7E63);

  /// Live drag position; null whenever the widget is showing the persisted
  /// value, so an external change isn't masked by a stale local copy.
  double? _dragging;

  @override
  void didUpdateWidget(covariant WAdhanVolumeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The commit landed (or the setting changed elsewhere) — hand control back
    // to the persisted value rather than keeping the drag position forever.
    if (oldWidget.value != widget.value) _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    final shown = _dragging ?? widget.value.toDouble();
    final hint = widget.hint;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTab ? 27.w : 18.w,
        isTab ? 10 : 12.h,
        isTab ? 27.w : 18.w,
        isTab ? 6 : 8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WAdhanIconCircle(icon: Icons.volume_up_rounded),
              SizedBox(width: isTab ? 18.w : 16.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('adhan_volume'.tr(), style: AppTextStyles.ink16W500),
                    if (hint != null) ...[
                      SizedBox(height: isTab ? 3 : 3.h),
                      Text(hint, style: AppTextStyles.grey12W400),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Pinned LTR: under RTL the percent sign would flip to the left
              // of the number, which reads as a different value at a glance.
              Text(
                '${shown.round()}%',
                style: AppTextStyles.grey12W400,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _green,
              thumbColor: _green,
              inactiveTrackColor: const Color(0xFFDCE5E1),
              trackHeight: 3.h,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: shown.clamp(0, 100),
              min: 0,
              max: 100,
              // 5-point steps: finer is not audible on a device whose ALARM
              // stream has ~7 discrete levels, and it makes the slider land on
              // round numbers.
              divisions: 20,
              onChanged: (v) => setState(() => _dragging = v),
              onChangeEnd: (v) => widget.onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
