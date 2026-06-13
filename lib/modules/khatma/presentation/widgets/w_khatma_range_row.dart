import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// A tappable "from/to" range row opening the mushaf at [pageNumber].
class WKhatmaRangeRow extends StatelessWidget {
  const WKhatmaRangeRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
  });

  final String title;
  final String subtitle;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(QuranRoutes.readerFromPage(pageNumber)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded, size: 22),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: TextStyle(fontSize: 15.sp)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
