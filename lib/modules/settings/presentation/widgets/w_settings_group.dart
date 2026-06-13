import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WSettingsGroup extends StatelessWidget {
  const WSettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: const Color(0xFFE2ECE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(
                  height: 1,
                  indent: 14.w,
                  endIndent: 14.w,
                  color: const Color(0xFFEDF1EF),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
