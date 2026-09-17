import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// One option of a [WPlayerChoiceRow].
class PlayerChoice<T> {
  const PlayerChoice({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Branded segmented control for the player sheet: equal-width pills inside
/// a light track, the selected one filled with the brand green.
///
/// With icons the pills stack icon-over-label so four Arabic or English
/// labels stay legible on a phone; without, they are a single text line.
class WPlayerChoiceRow<T> extends StatelessWidget {
  const WPlayerChoiceRow({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  final List<PlayerChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: playerTrackDecoration(context),
      child: Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) SizedBox(width: 3.w),
            Expanded(
              child: _Pill(
                choice: choices[i],
                selected: choices[i].value == selected,
                onTap: () => onChanged(choices[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill<T> extends StatelessWidget {
  const _Pill({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final PlayerChoice<T> choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final fg = selected ? Colors.white : brand.onSurface;
    final icon = choice.icon;
    final label = Text(
      choice.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: fg,
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: 6.w,
            vertical: icon == null ? 9.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: selected ? brand.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: brand.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: icon == null
              ? label
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18.r, color: fg),
                    SizedBox(height: 3.h),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}

/// Compact −/value/+ control in the same track as [WPlayerChoiceRow]. A null
/// callback disables that side at its bound.
class WPlayerStepper extends StatelessWidget {
  const WPlayerStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: playerTrackDecoration(context),
      child: Row(
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: context.brand.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? brand.primary.withValues(alpha: 0.10)
          : brand.surfaceMuted,
      borderRadius: BorderRadius.circular(9.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: SizedBox(
          width: 40.w,
          height: 34.h,
          child: Icon(
            icon,
            size: 20.r,
            color: enabled ? brand.primary : brand.muted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// The light track every player control sits in, so pills, steppers and
/// dropdowns read as one family against the card.
BoxDecoration playerTrackDecoration(BuildContext context) => BoxDecoration(
  color: context.brand.surface,
  borderRadius: BorderRadius.circular(12.r),
  border: Border.all(color: context.brand.border),
);
