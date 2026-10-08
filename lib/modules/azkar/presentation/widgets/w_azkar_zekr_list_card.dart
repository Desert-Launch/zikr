import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_tag.dart';

/// A zekr row in the category list: favorite toggle, the Arabic text, an
/// optional virtue tag, and the repeat count — left off the closing card,
/// which has nothing to count.
class WAzkarZekrListCard extends StatelessWidget {
  const WAzkarZekrListCard({
    super.key,
    required this.item,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final MAzkarItem item;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final virtue = item.virtue(LocalizeAndTranslate.getLanguageCode());
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
            if (!item.isClosing) ...[
              CircleAvatar(
                radius: 17.r,
                backgroundColor: const Color(0xFFFF7A21),
                child: Text(
                  '${item.repeat}',
                  style: TextStyle(color: Colors.white, fontSize: 11.sp),
                ),
              ),
              SizedBox(width: 8.w),
            ],
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
                  if (virtue != null && virtue.isNotEmpty) ...[
                    SizedBox(height: 7.h),
                    WAzkarTag(
                      text: virtue,
                      color: const Color(0xFF007A58),
                      outlined: true,
                    ),
                  ],
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
