import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_search_field.dart';
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
  const WQuranIndexSheet({super.key, required this.onOpenPage});

  /// Called after the sheet closes, with the chosen Mushaf page.
  final ValueChanged<int> onOpenPage;

  /// Opens the sheet over the current route.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onOpenPage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WQuranIndexSheet(onOpenPage: onOpenPage),
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

  /// Fans the query out to both the surah-name filter and the ayah search —
  /// same behaviour as the index screen's header.
  void _onQueryChanged(String query) {
    _cubit.setQuery(query);
    _searchCubit.setQuery(query);
  }

  void _open(int page) {
    Navigator.of(context).pop();
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
            leadingSlivers: [
              SliverToBoxAdapter(
                child: _Header(onQueryChanged: _onQueryChanged),
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
