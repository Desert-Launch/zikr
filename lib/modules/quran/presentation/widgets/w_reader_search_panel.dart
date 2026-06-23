import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_results.dart';

/// Search drawer that slides down from beneath [WReaderTopBar]. It owns its own
/// [CBQuranSearch] and reuses [WSearchResults], but routes result taps back into
/// the open reader (jump in place + highlight) instead of pushing a new screen.
class WReaderSearchPanel extends StatefulWidget {
  const WReaderSearchPanel({super.key, required this.onHitTap});

  /// Called with the tapped ayah and its page so the reader can jump there.
  final void Function(ParamAyahRef ref, int page) onHitTap;

  @override
  State<WReaderSearchPanel> createState() => _WReaderSearchPanelState();
}

class _WReaderSearchPanelState extends State<WReaderSearchPanel> {
  late final CBQuranSearch _search = Modular.get<CBQuranSearch>();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _search.close();
    super.dispose();
  }

  void _onSearchOpenChanged(bool open) {
    if (open) {
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      _controller.clear();
      _search.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _search,
      child: BlocListener<CBMushafReader, SMushafReader>(
        listenWhen: (a, b) => a.searchOpen != b.searchOpen,
        listener: (_, s) => _onSearchOpenChanged(s.searchOpen),
        child: BlocSelector<CBMushafReader, SMushafReader, bool>(
          selector: (s) => s.searchOpen,
          builder: (context, open) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: open
                  ? _Panel(controller: _controller, focus: _focus, onHitTap: widget.onHitTap)
                  : const SizedBox(width: double.infinity),
            );
          },
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.controller,
    required this.focus,
    required this.onHitTap,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final void Function(ParamAyahRef ref, int page) onHitTap;

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBQuranSearch>(context);
    return Material(
      color: context.brand.surface,
      elevation: 6,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              focusNode: focus,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(fontSize: 16.sp),
              onChanged: cubit.setQuery,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'search_hint'.tr(),
                hintStyle: TextStyle(fontSize: 13.sp, color: context.brand.muted),
                filled: true,
                fillColor: context.brand.background,
                prefixIcon: const Icon(Icons.search, color: AppColorsLight.primary),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, v, __) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            controller.clear();
                            cubit.clear();
                          },
                        ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: context.brand.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: context.brand.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColorsLight.primary, width: 1.4),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 0.5.sh,
              child: WSearchResults(
                onHitTap: (hit) => onHitTap(hit.ref, hit.page),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
