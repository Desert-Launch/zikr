import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Circular icon button used in the home header bar.
class WHomeHeaderButton extends StatelessWidget {
  const WHomeHeaderButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 25.r,
      child: Padding(
        padding: EdgeInsets.all(5.r),
        child: Icon(icon, color: Colors.white, size: 25.r),
      ),
    );
  }
}
