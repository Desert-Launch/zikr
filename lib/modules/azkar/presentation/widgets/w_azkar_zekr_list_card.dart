import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_tag.dart';

/// A zekr row in the category list: favorite toggle, the Arabic text, optional
/// source / virtue tags, and the repeat count.
class WAzkarZekrListCard extends StatelessWidget {
  const WAzkarZekrListCard({
    super.key,
    required this.item,
    required this.favorite,
    required this.gold,
    required this.onFavorite,
    required this.onTap,
  });

  final MAzkarItem item;
  final bool favorite;
  final Color gold;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = item.source;
    final virtue = item.virtueAr;
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17.r,
              backgroundColor: const Color(0xFFFF7A21),
              child: Text(
                '${item.repeat}',
                style: TextStyle(color: Colors.white, fontSize: 11.sp),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The zekr body is always Arabic, whatever the UI language.
                  Text(
                    item.textAr,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.amiri(fontSize: 16.sp, height: 1.65),
                  ),
                  SizedBox(height: 7.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 4.h,
                    children: [
                      if (source != null && source.isNotEmpty)
                        WAzkarTag(text: source, color: gold),
                      if (virtue != null && virtue.isNotEmpty)
                        WAzkarTag(
                          text: virtue,
                          color: const Color(0xFF007A58),
                          outlined: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18.r,
                color: favorite ? Colors.red : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
