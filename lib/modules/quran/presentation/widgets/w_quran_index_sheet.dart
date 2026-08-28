import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_search_field.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_content.dart';

/// The Quran index as a draggable bottom sheet, opened from the reader's index
/// icon instead of navigating away from the page you're reading.
///
/// Renders [WQuranIndexContent] — the exact same body as the standalone index
/// screen, not a copy. Picking an entry pops the sheet and reports the target
/// page, which the reader jumps to in place.
class WQuranIndexSheet extends StatefulWidget {
  const WQuranIndexSheet({
    super.key,
    required this.onOpenPage,
    this.onOpenAyah,
  });

  /// Called after the sheet closes, with the chosen Mushaf page.
  final ValueChanged<int> onOpenPage;

  /// Called after the sheet closes for a search result, which names a verse as
  /// well as a page so the reader can highlight it. Falls back to
  /// [onOpenPage] when absent.
  final void Function(ParamAyahRef? ref, int page)? onOpenAyah;

  /// Opens the sheet over the current route.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onOpenPage,
    void Function(ParamAyahRef? ref, int page)? onOpenAyah,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WQuranIndexSheet(
        onOpenPage: onOpenPage,
        onOpenAyah: onOpenAyah,
      ),
    );
  }

  @override
  State<WQuranIndexSheet> createState() => _WQuranIndexSheetState();
}

class _WQuranIndexSheetState extends State<WQuranIndexSheet> {
  // Own instances (both cubits are registered as factories), disposed with the
  // sheet so the index screen's own state is never disturbed.
  late final CBSurahList _cubit = Modular.get<CBSurahList>()..loadInitial();
  late final CBQuranSearch _searchCubit = Modular.get<CBQuranSearch>();

  @override
  void dispose() {
    _cubit.close();
    _searchCubit.close();
    super.dispose();
  }

  void _open(int page) {
    Navigator.of(context).pop();
    widget.onOpenPage(page);
  }

  /// A search result was tapped: close the sheet, then hand the reader the
  /// verse (and its page) to jump to.
  void _openAyah(ParamAyahRef? ref, int page) {
    Navigator.of(context).pop();
    final open = widget.onOpenAyah;
    if (open != null) {
      open(ref, page);
      return;
    }
    widget.onOpenPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          clipBehavior: Clip.antiAlias,
          child: WQuranIndexContent(
            cubit: _cubit,
            searchCubit: _searchCubit,
            controller: controller,
            showSummary: false,
            onOpenPage: _open,
            onOpenAyah: _openAyah,
            leadingSlivers: [
              SliverToBoxAdapter(
                child: _Header(onQueryChanged: _searchCubit.setQuery),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onQueryChanged});

  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.brand.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            WSearchField(onChanged: onQueryChanged),
          ],
        ),
      ),
    );
  }
}
