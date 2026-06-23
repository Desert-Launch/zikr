import 'package:flutter/material.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_rule.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';

/// Theme-aware Tajweed colours — the payoff of Approach B.
///
/// Because *we* set each token's colour (instead of a baked colour font), the
/// rule hues adapt to the reader theme. The light/sepia map keeps the familiar
/// printed-Mushaf hues on warm paper; the dark map lifts them for contrast on
/// `#121212`, and the base (non-rule) text becomes white. See
/// `docs/plans/Tajweed_Approach_B_Plan.md` §6.

/// Light/sepia hues — the established legend palette, readable on warm paper.
const Map<ETajweedRule, Color> _lightMap = {
  ETajweedRule.maddObligatory: Color(0xFFB50000),
  ETajweedRule.maddPermissible: Color(0xFFE36A00),
  ETajweedRule.ghunnah: Color(0xFF09893B),
  ETajweedRule.qalqalah: Color(0xFF2A36D6),
  ETajweedRule.ikhfaIdgham: Color(0xFF1E8FD6),
  ETajweedRule.iqlab: Color(0xFF1F8A91),
  ETajweedRule.silent: Color(0xFF9A9A9A),
};

/// Dark hues — same families, brightened for contrast on a near-black surface.
const Map<ETajweedRule, Color> _darkMap = {
  ETajweedRule.maddObligatory: Color(0xFFFF6B6B),
  ETajweedRule.maddPermissible: Color(0xFFFFA64D),
  ETajweedRule.ghunnah: Color(0xFF4FD37A),
  ETajweedRule.qalqalah: Color(0xFF8A92FF),
  ETajweedRule.ikhfaIdgham: Color(0xFF5BC3FF),
  ETajweedRule.iqlab: Color(0xFF54CFD8),
  ETajweedRule.silent: Color(0xFF9E9E9E),
};

/// The colour for [rule] under [brightness].
Color tajweedColour(ETajweedRule rule, {required Brightness brightness}) {
  final map = brightness == Brightness.dark ? _darkMap : _lightMap;
  return map[rule] ?? tajweedBaseColour(brightness: brightness);
}

/// Colour for plain (uncoloured) text — near-black on light, white on dark.
Color tajweedBaseColour({required Brightness brightness}) =>
    brightness == Brightness.dark ? Colors.white : const Color(0xFF0A0A0A);

/// Reader theme → brightness for the maps above (sepia is a light surface).
Brightness tajweedBrightness(ReaderTheme theme) =>
    theme == ReaderTheme.dark ? Brightness.dark : Brightness.light;
