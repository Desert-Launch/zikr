import 'package:flutter/material.dart';

class WNightModeSwitch extends StatelessWidget {
  const WNightModeSwitch({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75,
      child: Switch(
        value: enabled,
        activeTrackColor: const Color(0xFF2F7E63),
        inactiveTrackColor: const Color(0xFFF7F7F7),
        inactiveThumbColor: Colors.white,
        trackOutlineColor: WidgetStateProperty.all(const Color(0xFFEDEDED)),
        thumbColor: WidgetStateProperty.all(Colors.white),
        onChanged: onChanged,
      ),
    );
  }
}
