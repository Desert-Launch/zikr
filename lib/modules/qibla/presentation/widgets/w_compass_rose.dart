import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_qibla_dot.dart';

class WCompassRose extends StatelessWidget {
  const WCompassRose({super.key});

  static const _tickColor = Color(0xFFB8B4A8);
  static const _labelColor = Color(0xFF7B7768);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Intermediate dots (NE, SE, SW, NW).
        const WQiblaDot(alignment: Alignment(0.62, -0.62)),
        const WQiblaDot(alignment: Alignment(0.62, 0.62)),
        const WQiblaDot(alignment: Alignment(-0.62, 0.62)),
        const WQiblaDot(alignment: Alignment(-0.62, -0.62)),
        // Cardinals: label + tick.
        _cardinal(
          align: Alignment.topCenter,
          label: 'qibla_north'.tr(),
          axis: Axis.vertical,
          labelFirst: true,
        ),
        _cardinal(
          align: Alignment.bottomCenter,
          label: 'qibla_south'.tr(),
          axis: Axis.vertical,
          labelFirst: false,
        ),
        _cardinal(
          align: Alignment.centerRight,
          label: 'qibla_east'.tr(),
          axis: Axis.horizontal,
          labelFirst: true,
        ),
        _cardinal(
          align: Alignment.centerLeft,
          label: 'qibla_west'.tr(),
          axis: Axis.horizontal,
          labelFirst: false,
        ),
      ],
    );
  }

  Widget _cardinal({
    required Alignment align,
    required String label,
    required Axis axis,
    required bool labelFirst,
  }) {
    final tick = Container(
      width: axis == Axis.vertical ? 3.w : 16.w,
      height: axis == Axis.vertical ? 16.h : 3.w,
      decoration: BoxDecoration(
        color: _tickColor,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _labelColor,
      ),
    );
    final gap = SizedBox(width: 8.w, height: 8.h);
    final children = labelFirst ? [text, gap, tick] : [tick, gap, text];
    return Align(
      alignment: align,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: axis == Axis.vertical
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
