import 'package:flutter/material.dart';

/// A faint outlined circle used as decoration inside the azkar headers.
class WAzkarOutlineCircle extends StatelessWidget {
  const WAzkarOutlineCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 4),
      ),
    );
  }
}
