import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_wird_content.dart';

/// Highlighted suggested wird card on the wirds screen.
class WKhatmaSuggestedWird extends StatelessWidget {
  const WKhatmaSuggestedWird({
    super.key,
    required this.wird,
    required this.onTap,
  });

  final MKhatmaWird wird;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFDDE6E0)),
        ),
        child: WKhatmaWirdContent(wird: wird),
      ),
    );
  }
}
