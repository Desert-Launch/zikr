import 'package:flutter/material.dart';

/// The toggle used in the trailing slot of a [WSettingsRow].
///
/// Scaled down to .75 so a Material switch sits inside the compact settings
/// row without stretching it — the same treatment the alarm-permission rows
/// already used, lifted here so every settings surface toggles identically.
///
/// A null [onChanged] renders the switch disabled, for a toggle that only
/// applies while some other setting is on.
class WSettingsSwitch extends StatelessWidget {
  const WSettingsSwitch({required this.value, required this.onChanged, super.key});

  static const _green = Color(0xFF2F7E63);

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: .75,
      child: Switch(
        value: value,
        activeTrackColor: _green,
        thumbColor: WidgetStateProperty.all(
          value && onChanged != null ? Colors.white : Colors.grey.shade400,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
