import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/widgets/share_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_section.dart';

/// "Range" — the first and last verse of the share.
///
/// Both rows read as buttons and neither opens anything until it is tapped:
/// the sheet opens on one verse, which is what most shares are, and a wheel
/// taking up a third of the sheet to say so would be in the way.
class WShareRangePicker extends StatefulWidget {
  const WShareRangePicker({required this.surahName, super.key});

  final String surahName;

  @override
  State<WShareRangePicker> createState() => _WShareRangePickerState();
}

class _WShareRangePickerState extends State<WShareRangePicker> {
  FixedExtentScrollController? _wheel;

  /// Which wheel the controller belongs to — the edge it is editing and the
  /// verse it counts up from. The two together decide what item index means
  /// what, so a change to either needs a controller that agrees with it.
  String? _signature;

  /// Item index the wheel was last told to show. Guards the difference between
  /// the reader spinning it (which must not be animated back) and the value
  /// being changed elsewhere — tapping the other row, or a range that clamped.
  int? _shown;

  /// True while the wheel is being moved by us rather than by a finger.
  ///
  /// A wheel reports every item it passes, so animating it from verse 80 to
  /// verse 65 would otherwise walk the range through all fifteen verses in
  /// between.
  bool _animating = false;

  @override
  void dispose() {
    _wheel?.dispose();
    super.dispose();
  }

  /// Hands back the controller for the wheel described by [state], building a
  /// fresh one whenever the wheel it belongs to changes underneath it.
  FixedExtentScrollController _controllerFor(SAyahShare state) {
    final first = state.wheelFirst;
    final value = state.wheelValue;
    final signature = '${state.edge}-$first';
    final existing = _wheel;
    if (signature == _signature && existing != null) {
      _syncWheel(existing, value - first);
      return existing;
    }
    final created = FixedExtentScrollController(initialItem: value - first);
    _signature = signature;
    _shown = value - first;
    _wheel = created;
    // The wheel still on screen this frame is holding the old controller;
    // disposing it before that build is done would pull it out from under it.
    if (existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => existing.dispose());
    }
    return created;
  }

  /// Moves an existing wheel to [item] when something other than the reader's
  /// finger changed the value.
  void _syncWheel(FixedExtentScrollController wheel, int item) {
    if (_shown == item) return;
    _shown = item;
    if (!wheel.hasClients || wheel.selectedItem == item) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !wheel.hasClients) return;
      _animating = true;
      try {
        await wheel.animateToItem(
          item,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } finally {
        _animating = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBAyahShare>(context);
    return BlocBuilder<CBAyahShare, SAyahShare>(
      buildWhen: (a, b) =>
          a.from != b.from ||
          a.to != b.to ||
          a.ayahCount != b.ayahCount ||
          a.edge != b.edge,
      builder: (context, state) {
        final open = state.edge;
        return WShareSection(
          label: 'quran_share_range'.tr(),
          children: [
            _EdgeRow(
              title: 'quran_share_from'.tr(),
              value: shareAyahLabel(widget.surahName, state.from),
              open: open == EShareRangeEdge.from,
              onTap: () => cubit.setEdge(EShareRangeEdge.from),
            ),
            const WShareRowDivider(),
            _EdgeRow(
              title: 'quran_share_to'.tr(),
              value: shareAyahLabel(widget.surahName, state.to),
              open: open == EShareRangeEdge.to,
              onTap: () => cubit.setEdge(EShareRangeEdge.to),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: open == null
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WShareRowDivider(),
                        SizedBox(
                          height: 150.h,
                          child: _Wheel(
                            controller: _controllerFor(state),
                            first: state.wheelFirst,
                            last: state.ayahCount,
                            surahName: widget.surahName,
                            onSelected: (ayah) {
                              if (_animating) return;
                              _shown = ayah - state.wheelFirst;
                              HapticFeedback.selectionClick();
                              cubit.setRangeValue(ayah);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// One end of the range: what it is called, and the verse it points at.
/// Tinted, with its chevron turned, while its wheel is open below.
class _EdgeRow extends StatelessWidget {
  const _EdgeRow({
    required this.title,
    required this.value,
    required this.open,
    required this.onTap,
  });

  final String title;
  final String value;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: open
          ? context.brand.primary.withValues(alpha: 0.07)
          : Colors.transparent,
      child: WShareRow(
        title: title,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: context.brand.primary,
              ),
            ),
            SizedBox(width: 4.w),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.expand_more_rounded,
                size: 18.r,
                color: context.brand.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.first,
    required this.last,
    required this.surahName,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;

  /// Lowest and highest verse the wheel offers, inclusive.
  final int first;
  final int last;

  final String surahName;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 34.h,
      diameterRatio: 1.6,
      perspective: 0.004,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 0.35,
      onSelectedItemChanged: (index) => onSelected(first + index),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: last - first + 1,
        builder: (context, index) => Center(
          child: Text(
            shareAyahLabel(surahName, first + index),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: context.brand.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
