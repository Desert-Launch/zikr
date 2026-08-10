import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';

/// Trailing mark for a settings row that is one option of a single-choice
/// group (pick a frequency, pick a mode).
class WSettingsCheck extends StatelessWidget {
  const WSettingsCheck({required this.selected, super.key});

  static const _green = Color(0xFF2F7E63);

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = context.isTablet ? 24.0 : 21.r;
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      color: selected ? _green : const Color(0xFFC9D2CD),
      size: size,
    );
  }
}
