import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_icon.dart';

/// A 0–100 loudness slider for a [WSettingsGroup] — the settings-surface twin
/// of the adhan screen's `WAdhanVolumeRow`, laid out like a [WSettingsRow]
/// with the slider across the full width underneath.
///
/// The drag is previewed locally and only [onChanged] on release commits it:
/// the reminder volumes are baked into every armed alarm, so a commit is a
/// whole reschedule, not a cheap write.
///
/// A null [onChanged] renders the row disabled, for a volume that only applies
/// while some other setting is on.
class WSettingsVolumeRow extends StatefulWidget {
  const WSettingsVolumeRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String title;

  /// Hint under [title], up to two lines.
  final String? subtitle;

  /// Persisted level, 0–100. Also the value the local preview resets to when
  /// the setting changes from elsewhere.
  final int value;

  /// Called once per gesture, on release — never mid-drag.
  final ValueChanged<int>? onChanged;

  @override
  State<WSettingsVolumeRow> createState() => _WSettingsVolumeRowState();
}

class _WSettingsVolumeRowState extends State<WSettingsVolumeRow> {
  static const _green = Color(0xFF2F7E63);

  /// Live drag position; null whenever the row is showing the persisted value,
  /// so an external change isn't masked by a stale local copy.
  double? _dragging;

  @override
  void didUpdateWidget(covariant WSettingsVolumeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    final shown = _dragging ?? widget.value.toDouble();
    final subtitle = widget.subtitle;
    final onChanged = widget.onChanged;
    final enabled = onChanged != null;
    final grey = GoogleFonts.cairo(
      fontSize: isTab ? 11.5 : 9.sp,
      color: const Color(0xFF858585),
      height: 1,
    );
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          27.w,
          isTab ? 9 : 11.h,
          27.w,
          isTab ? 6 : 8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                WSettingsIcon(
                  icon: shown == 0
                      ? Icons.volume_off_outlined
                      : Icons.volume_up_outlined,
                ),
                SizedBox(width: 18.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF303030),
                          fontSize: isTab ? 16 : 13.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: isTab ? 3 : 4.h),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: grey.copyWith(height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Pinned LTR: under RTL the percent sign would flip to the left
                // of the number, which reads as a different value at a glance.
                Text(
                  '${shown.round()}%',
                  style: grey,
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
                // 5-point steps, as on the adhan slider: the ALARM stream has
                // only ~7–15 discrete levels, so finer steps aren't audible.
                divisions: 20,
                onChanged: enabled
                    ? (v) => setState(() => _dragging = v)
                    : null,
                onChangeEnd: enabled ? (v) => onChanged(v.round()) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
