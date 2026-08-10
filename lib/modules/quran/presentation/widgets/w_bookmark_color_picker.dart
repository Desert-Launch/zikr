import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_bookmarks_sheet.dart';

/// A single bookmark colour choice. [hex] is the value persisted on the
/// bookmark (`MBookmark.colorHex`); [color] is the swatch shown in the picker.
class BookmarkSwatch {
  const BookmarkSwatch({required this.hex, required this.color});

  final String hex;
  final Color color;
}

/// The palette offered when saving a bookmark from the Mushaf. Each colour
/// holds at most one verse, so this list also caps how many bookmarks the
/// reader can hold at a time.
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

/// Stored hexes may or may not carry the leading `#` and vary in case, so all
/// colour comparisons go through this. A colourless (legacy) bookmark reads as
/// the default swatch.
String _normHex(String? hex) {
  final raw = (hex == null || hex.trim().isEmpty) ? _kDefaultBookmarkColorHex : hex;
  return raw.replaceFirst('#', '').trim().toUpperCase();
}

/// The vivid bookmark colour (icon / accent), with a sensible default.
Color bookmarkColorFromHex(String? hex) => _parseHex(hex) ?? _kDefaultBookmarkColor;

/// The translucent tint painted behind a bookmarked ayah in the Mushaf.
Color bookmarkHighlightFromHex(String? hex) => bookmarkColorFromHex(hex).withValues(alpha: 0.20);

/// What the user chose in the bookmark colour sheet.
class BookmarkPickerChoice {
  /// Save (or recolour) the bookmark with [hex]. [replaces] is the verse that
  /// currently owns that colour and must be un-bookmarked first — the user
  /// already confirmed the swap in the picker.
  const BookmarkPickerChoice.color(String this.hex, {this.replaces}) : remove = false, openAll = false;

  /// Un-bookmark the ayah — the user tapped the colour it already carries.
  const BookmarkPickerChoice.remove() : hex = null, remove = true, replaces = null, openAll = false;

  /// Leave the ayah alone and show the full bookmarks list instead.
  const BookmarkPickerChoice.openAll() : hex = null, remove = false, replaces = null, openAll = true;

  final String? hex;
  final bool remove;
  final ParamAyahRef? replaces;
  final bool openAll;
}

/// Presents the colour picker as a modal sheet for [currentRef].
///
/// [owners] maps each taken colour to the single verse holding it, so the sheet
/// can caption every swatch and warn before a colour is reassigned.
/// [selectedHex] is the colour the ayah is *currently* bookmarked with — pass
/// `null` when it isn't bookmarked, and pass [isBookmarked] `true` with a null
/// hex for a legacy colourless bookmark. Resolves to `null` if the sheet was
/// dismissed without choosing.
Future<BookmarkPickerChoice?> showBookmarkColorPicker(
  BuildContext context, {
  required ParamAyahRef currentRef,
  required Map<String, ParamAyahRef> owners,
  String? selectedHex,
  bool isBookmarked = false,
}) {
  return showModalBottomSheet<BookmarkPickerChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    // The swatch captions and the "all bookmarks" button push this past the
    // 9/16-of-screen cap a plain modal sheet imposes, which silently clips the
    // bottom of the sheet on shorter devices.
    isScrollControlled: true,
    builder: (_) => WBookmarkColorPicker(
      currentRef: currentRef,
      owners: owners,
      selectedHex: selectedHex,
      isBookmarked: isBookmarked,
    ),
  );
}

/// Which verse holds each bookmark colour, derived from the reader's live
/// bookmark map. Colours are unique by design; if legacy data has two verses on
/// one colour the later entry wins here and the picker treats it as the owner.
Map<String, ParamAyahRef> bookmarkOwnersOf(CBMushafReader cubit) {
  final owners = <String, ParamAyahRef>{};
  cubit.state.bookmarks.forEach((ayahKey, hex) {
    owners[_normHex(hex)] = ParamAyahRef.fromKey(ayahKey);
  });
  return owners;
}

/// Opens the picker for [ref] pre-marked with the colour it currently carries,
/// then applies the user's choice through [cubit]: a free colour saves, a
/// colour held by another verse moves the bookmark (after confirmation),
/// tapping the already-selected colour un-bookmarks, dismissing changes nothing.
///
/// Shared by the ayah action sheet and the reader's long-press gesture so both
/// entry points behave identically.
///
/// Returns `false` when the user left through the full bookmarks list, which
/// drives its own navigation (and its own highlight) — callers must not clear
/// the reader selection in that case or they'd wipe the verse just jumped to.
Future<bool> toggleAyahBookmark(BuildContext context, ParamAyahRef ref, CBMushafReader cubit) async {
  final wasBookmarked = cubit.isBookmarked(ref);
  final choice = await showBookmarkColorPicker(
    context,
    currentRef: ref,
    owners: bookmarkOwnersOf(cubit),
    selectedHex: cubit.bookmarkColorOf(ref),
    isBookmarked: wasBookmarked,
  );
  if (choice == null || !context.mounted) return true;

  if (choice.openAll) {
    await WReaderBookmarksSheet.show(context, onOpenAyah: cubit.requestJumpToAyah);
    return false;
  }

  final hex = choice.hex;
  if (choice.remove) {
    await cubit.removeBookmark(ref);
  } else if (hex != null) {
    // One verse per colour: free the previous holder before claiming it.
    final replaced = choice.replaces;
    if (replaced != null) await cubit.removeBookmark(replaced);
    await cubit.saveBookmark(ref, hex);
  } else {
    return true;
  }
  AppAlert.success(choice.remove ? 'bookmark_removed'.tr() : 'bookmark_saved'.tr());
  return true;
}

/// Bottom-sheet body letting the user pick a colour for a bookmark. Every
/// swatch is captioned with the verse it currently holds, tapping a free colour
/// pops with that swatch's `hex`, tapping the ayah's own colour pops with a
/// remove choice, and tapping a colour owned by another verse asks first.
class WBookmarkColorPicker extends StatefulWidget {
  const WBookmarkColorPicker({
    super.key,
    required this.currentRef,
    this.owners = const <String, ParamAyahRef>{},
    this.selectedHex,
    this.isBookmarked = false,
  });

  final ParamAyahRef currentRef;

  /// Normalised `RRGGBB` → the verse bookmarked with that colour.
  final Map<String, ParamAyahRef> owners;

  final String? selectedHex;
  final bool isBookmarked;

  @override
  State<WBookmarkColorPicker> createState() => _WBookmarkColorPickerState();
}

class _WBookmarkColorPickerState extends State<WBookmarkColorPicker> {
  /// Surah lookup (number → metadata) so swatch captions can name the verse.
  Map<int, MSurah> _surahs = const {};

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await Modular.get<DSLocalQuran>().loadSurahs();
    if (!mounted) return;
    setState(() => _surahs = {for (final s in surahs) s.number: s});
  }

  /// Whether the ayah being edited is the one holding [swatch]'s colour.
  bool _isSelected(BookmarkSwatch swatch) {
    if (!widget.isBookmarked) return false;
    return _normHex(swatch.hex) == _normHex(widget.selectedHex);
  }

  /// The verse holding [swatch]'s colour, or `null` when the colour is free.
  ParamAyahRef? _ownerOf(BookmarkSwatch swatch) => widget.owners[_normHex(swatch.hex)];

  String _surahNameOf(ParamAyahRef ref) {
    final arabic = _surahs[ref.surah]?.arabic ?? '';
    return arabic.isNotEmpty ? arabic : '${'quran_surah_label'.tr()} ${ref.surah}';
  }

  String _fullLabelOf(ParamAyahRef ref) => '${_surahNameOf(ref)} · ${'quran_ayah_label'.tr()} ${ref.ayah}';

  Future<void> _onSwatch(BookmarkSwatch swatch) async {
    // The ayah's own colour → toggle the bookmark off.
    if (_isSelected(swatch)) {
      Navigator.of(context).pop(const BookmarkPickerChoice.remove());
      return;
    }

    final owner = _ownerOf(swatch);
    if (owner != null && owner != widget.currentRef) {
      final replace = await _confirmReplace(owner);
      // Declining keeps the sheet open so another colour can be picked.
      if (replace != true || !mounted) return;
      Navigator.of(context).pop(BookmarkPickerChoice.color(swatch.hex, replaces: owner));
      return;
    }

    Navigator.of(context).pop(BookmarkPickerChoice.color(swatch.hex));
  }

  /// Asks whether the colour should be moved off [owner] onto the current ayah.
  Future<bool?> _confirmReplace(ParamAyahRef owner) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('bookmarks_color_taken_title'.tr(), style: AppTextStyles.ink16W700),
        content: Text(
          'bookmarks_color_taken_body'.tr().replaceFirst('{{verse}}', _fullLabelOf(owner)),
          style: AppTextStyles.grey14W400,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('bookmarks_color_taken_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('bookmarks_color_taken_replace'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
        decoration: BoxDecoration(color: context.brand.surface, borderRadius: BorderRadius.circular(20.r)),
        // Scrolls rather than overflows if the captions wrap tall (large text
        // scale, long surah names) — the button below must always be reachable.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: context.brand.border, borderRadius: BorderRadius.circular(2.r)),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: context.brand.primary,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Text('bookmarks_color_title'.tr(), style: AppTextStyles.ink16W700),
                ],
              ),
              SizedBox(height: 4.h),
              Text('bookmarks_color_one_each'.tr(), textAlign: TextAlign.center, style: AppTextStyles.grey12W400),
              SizedBox(height: 18.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: kBookmarkSwatches
                    .map((s) {
                      final owner = _ownerOf(s);
                      return Expanded(
                        child: _Swatch(
                          swatch: s,
                          selected: _isSelected(s),
                          owner: owner,
                          ownerName: owner == null ? '' : _surahNameOf(owner),
                          onTap: () => _onSwatch(s),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              if (widget.isBookmarked) ...[
                SizedBox(height: 14.h),
                Text('bookmarks_color_remove_hint'.tr(), textAlign: TextAlign.center, style: AppTextStyles.grey12W400),
              ],
              SizedBox(height: 16.h),
              // Full list — every saved verse, not just the five colours.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(const BookmarkPickerChoice.openAll()),
                  icon: Icon(Icons.bookmarks_rounded, size: 18.r),
                  label: Text('bookmarks_all'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.brand.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One colour choice: the swatch itself plus a caption naming the verse it
/// holds (an em-dash when the colour is still free).
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.swatch,
    required this.selected,
    required this.owner,
    required this.ownerName,
    required this.onTap,
  });

  final BookmarkSwatch swatch;

  /// Whether the ayah being edited is bookmarked with this colour. Draws the
  /// ring + check, and turns the tap into an un-bookmark.
  final bool selected;

  /// The verse currently holding this colour, if any.
  final ParamAyahRef? owner;

  /// Arabic surah name of [owner]; empty while the surah index is still loading.
  final String ownerName;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ref = owner;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: swatch.color,
                shape: BoxShape.circle,
                border: selected ? Border.all(color: context.brand.onSurface, width: 3) : null,
                boxShadow: [
                  BoxShadow(color: swatch.color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: selected ? Icon(Icons.check_rounded, color: Colors.white, size: 22.r) : null,
            ),
            SizedBox(height: 6.h),
            if (ref == null)
              Text('—', style: AppTextStyles.grey12W400)
            else ...[
              Text(
                ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 12.sp, fontWeight: FontWeight.w700, color: context.brand.onSurface),
              ),
              Text(
                '${'quran_ayah_label'.tr()} ${ref.ayah}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.grey12W400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
