import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// Shared section label used across the khatma screens (plans, tracker, wirds).
///
/// The original screens rendered this slightly differently, so the layout is
/// preserved via [padding] (call sites pass the exact directional padding they
/// used) and [aligned] (the tracker screen wrapped the label in an
/// [Align] instead of relying on [TextAlign.end]).
class WKhatmaSectionLabel extends StatelessWidget {
  const WKhatmaSectionLabel(
    this.text, {
    super.key,
    this.padding,
    this.aligned = false,
  });

  final String text;
  final EdgeInsetsGeometry? padding;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? EdgeInsetsDirectional.only(end: 5.w, bottom: 6.h);
    final label = Text(
      text,
      textAlign: aligned ? null : TextAlign.end,
      style: AppTextStyles.grey14W400,
    );
    final padded = Padding(padding: effectivePadding, child: label);
    if (!aligned) return padded;
    return Align(alignment: AlignmentDirectional.centerEnd, child: padded);
  }
}
