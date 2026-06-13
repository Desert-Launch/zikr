import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_wird_content.dart';

/// Tappable wird row in the "all wirds" list on the wirds screen.
class WKhatmaWirdRow extends StatelessWidget {
  const WKhatmaWirdRow({super.key, required this.wird, required this.onTap});

  final MKhatmaWird wird;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: WKhatmaWirdContent(wird: wird),
      ),
    );
  }
}
