import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// A single bookmark colour choice. [hex] is the value persisted on the
/// bookmark (`MBookmark.colorHex`); [color] is the swatch shown in the picker.
class BookmarkSwatch {
  const BookmarkSwatch({required this.hex, required this.color});

  final String hex;
  final Color color;
}

/// The palette offered when saving a bookmark from the Mushaf.
const List<BookmarkSwatch> kBookmarkSwatches = [
  BookmarkSwatch(hex: '#EF4444', color: Color(0xFFEF4444)), // red
  BookmarkSwatch(hex: '#F59E0B', color: Color(0xFFF59E0B)), // amber
  BookmarkSwatch(hex: '#10B981', color: Color(0xFF10B981)), // green
  BookmarkSwatch(hex: '#3B82F6', color: Color(0xFF3B82F6)), // blue
  BookmarkSwatch(hex: '#8B5CF6', color: Color(0xFF8B5CF6)), // purple
];

/// Fallback colour for bookmarks saved without an explicit colour.
const Color _kDefaultBookmarkColor = Color(0xFF10B981);

/// Parses a stored `colorHex` (`#RRGGBB`, `RRGGBB`, or `AARRGGBB`) into a
/// [Color]. Returns `null` for empty/invalid values so callers can fall back.
Color? _parseHex(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var h = hex.replaceFirst('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}

/// The vivid bookmark colour (icon / accent), with a sensible default.
Color bookmarkColorFromHex(String? hex) => _parseHex(hex) ?? _kDefaultBookmarkColor;

/// The translucent tint painted behind a bookmarked ayah in the Mushaf.
Color bookmarkHighlightFromHex(String? hex) =>
    bookmarkColorFromHex(hex).withValues(alpha: 0.20);

/// Presents the colour picker as a modal sheet. Resolves to the chosen `#hex`
/// string, or `null` if the user dismissed it without choosing.
Future<String?> showBookmarkColorPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const WBookmarkColorPicker(),
  );
}

/// Bottom-sheet body letting the user pick a colour for a new bookmark.
/// Tapping a swatch pops the sheet with that swatch's `hex`.
class WBookmarkColorPicker extends StatelessWidget {
  const WBookmarkColorPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.brand.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_rounded, color: context.brand.primary, size: 20.r),
                SizedBox(width: 8.w),
                Text('bookmarks_color_title'.tr(), style: AppTextStyles.ink16W700),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: kBookmarkSwatches
                  .map((s) => _Swatch(swatch: s))
                  .toList(growable: false),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.swatch});

  final BookmarkSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(swatch.hex),
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: swatch.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: swatch.color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
