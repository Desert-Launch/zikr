import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';

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
const String _kDefaultBookmarkColorHex = '#10B981';

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
Color bookmarkColorFromHex(String? hex) =>
    _parseHex(hex) ?? _kDefaultBookmarkColor;

/// The translucent tint painted behind a bookmarked ayah in the Mushaf.
Color bookmarkHighlightFromHex(String? hex) =>
    bookmarkColorFromHex(hex).withValues(alpha: 0.20);

/// What the user chose in the bookmark colour sheet.
class BookmarkPickerChoice {
  /// Save (or recolour) the bookmark with [hex].
  const BookmarkPickerChoice.color(String this.hex) : remove = false;

  /// Un-bookmark the ayah — the user tapped the colour it already carries.
  const BookmarkPickerChoice.remove() : hex = null, remove = true;

  final String? hex;
  final bool remove;
}

/// Presents the colour picker as a modal sheet.
///
/// [selectedHex] is the colour the ayah is *currently* bookmarked with — pass
/// `null` when it isn't bookmarked, and pass [isBookmarked] `true` with a null
/// hex for a legacy colourless bookmark. The matching swatch is ringed, and
/// tapping it resolves to [BookmarkPickerChoice.remove] (toggle off). Resolves
/// to `null` if the sheet was dismissed without choosing.
Future<BookmarkPickerChoice?> showBookmarkColorPicker(
  BuildContext context, {
  String? selectedHex,
  bool isBookmarked = false,
}) {
  return showModalBottomSheet<BookmarkPickerChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => WBookmarkColorPicker(
      selectedHex: selectedHex,
      isBookmarked: isBookmarked,
    ),
  );
}

/// Opens the picker for [ref] pre-marked with the colour it currently carries,
/// then applies the user's choice through [cubit]: a new colour saves/recolours,
/// tapping the already-selected colour un-bookmarks, dismissing changes nothing.
///
/// Shared by the ayah action sheet and the reader's long-press gesture so both
/// entry points behave identically.
Future<void> toggleAyahBookmark(
  BuildContext context,
  ParamAyahRef ref,
  CBMushafReader cubit,
) async {
  final wasBookmarked = cubit.isBookmarked(ref);
  final choice = await showBookmarkColorPicker(
    context,
    selectedHex: cubit.bookmarkColorOf(ref),
    isBookmarked: wasBookmarked,
  );
  if (choice == null) return;

  final hex = choice.hex;
  if (choice.remove) {
    await cubit.removeBookmark(ref);
  } else if (hex != null) {
    await cubit.saveBookmark(ref, hex);
  } else {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        choice.remove ? 'bookmark_removed'.tr() : 'bookmark_saved'.tr(),
      ),
    ),
  );
}

/// Bottom-sheet body letting the user pick a colour for a bookmark. Tapping a
/// swatch pops the sheet with that swatch's `hex`; tapping the already-selected
/// swatch pops with a remove choice.
class WBookmarkColorPicker extends StatelessWidget {
  const WBookmarkColorPicker({
    super.key,
    this.selectedHex,
    this.isBookmarked = false,
  });

  final String? selectedHex;
  final bool isBookmarked;

  /// Normalised comparison — stored hexes may or may not carry the leading `#`.
  bool _isSelected(BookmarkSwatch swatch) {
    if (!isBookmarked) return false;
    final current = selectedHex?.replaceFirst('#', '').toUpperCase();
    // A colourless legacy bookmark reads as the default swatch.
    final effective =
        current ??
        _kDefaultBookmarkColorHex.replaceFirst('#', '').toUpperCase();
    return swatch.hex.replaceFirst('#', '').toUpperCase() == effective;
  }

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
                Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: context.brand.primary,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'bookmarks_color_title'.tr(),
                  style: AppTextStyles.ink16W700,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: kBookmarkSwatches
                  .map((s) => _Swatch(swatch: s, selected: _isSelected(s)))
                  .toList(growable: false),
            ),
            if (isBookmarked) ...[
              SizedBox(height: 14.h),
              Text(
                'bookmarks_color_remove_hint'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.grey12W400,
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.swatch, required this.selected});

  final BookmarkSwatch swatch;

  /// Whether the ayah is currently bookmarked with this colour. Draws the ring
  /// + check, and turns the tap into an un-bookmark.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(
        selected
            ? const BookmarkPickerChoice.remove()
            : BookmarkPickerChoice.color(swatch.hex),
      ),
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 44.r,
        height: 44.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: swatch.color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: context.brand.onSurface, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: swatch.color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: Colors.white, size: 22.r)
            : null,
      ),
    );
  }
}
