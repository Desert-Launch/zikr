import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';

/// One minute-correction stepper: −  0  + for a single timing.
///
/// The value is shown signed (`+2`, `−1`, `0`) because the sign is the whole
/// meaning — an unsigned "2" leaves the user guessing which way the prayer
/// moved.
class WPrayerTuneRow extends StatelessWidget {
  const WPrayerTuneRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
    super.key,
  });

  /// Bound so a slip on the stepper can't put a prayer in the wrong half of
  /// the day. An hour either way is far more than any mosque's local variance.
  static const int limit = 60;

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: isTab ? 6 : 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: isTab ? 15 : 12.5.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF303030),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: minutes > -limit ? () => onChanged(minutes - 1) : null,
          ),
          SizedBox(
            width: 46.w,
            child: Text(
              _signed(minutes),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(
                fontSize: isTab ? 15 : 12.5.sp,
                fontWeight: FontWeight.w700,
                color: minutes == 0
                    ? const Color(0xFF9AA5A0)
                    : const Color(0xFF2F7E63),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: minutes < limit ? () => onChanged(minutes + 1) : null,
          ),
        ],
      ),
    );
  }

  String _signed(int value) =>
      value == 0 ? '0' : (value > 0 ? '+$value' : '−${value.abs()}');
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEFF5F2) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 19.r,
          color: enabled ? const Color(0xFF2F7E63) : const Color(0xFFC9D2CD),
        ),
      ),
    );
  }
}
