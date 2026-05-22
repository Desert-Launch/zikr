import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class SNQuranSearch extends StatefulWidget {
  const SNQuranSearch({super.key});

  @override
  State<SNQuranSearch> createState() => _SNQuranSearchState();
}

class _SNQuranSearchState extends State<SNQuranSearch> {
  late final CBQuranSearch _cubit = Modular.get<CBQuranSearch>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        appBar: Text(
          'search_title'.tr(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.brand.background,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(fontSize: 16.sp),
                onChanged: _cubit.setQuery,
                decoration: InputDecoration(
                  hintText: 'search_hint'.tr(),
                  hintStyle: TextStyle(fontSize: 13.sp, color: context.brand.muted),
                  filled: true,
                  fillColor: context.brand.surface,
                  prefixIcon: const Icon(Icons.search, color: AppColorsLight.primary),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (_, v, __) => v.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _controller.clear();
                              _cubit.clear();
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
            ),
            const Expanded(child: _Results()),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBQuranSearch, SQuranSearch>(
      builder: (context, state) {
        if (state.query.trim().length < 2) {
          return Center(
            child: Text(
              'search_min_chars'.tr(),
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
            ),
          );
        }
        if (state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == LoadStatus.error) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                state.error ?? 'common_error'.tr(),
                style: TextStyle(fontSize: 13.sp, color: AppColors.semanticDanger),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (state.results.isEmpty) {
          return Center(
            child: Text(
              'search_no_results'.tr(),
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    'search_results_count'
                        .tr()
                        .replaceFirst('{{count}}', '${state.results.length}'),
                    style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: 24.h),
                itemCount: state.results.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1.h, color: context.brand.border),
                itemBuilder: (_, i) =>
                    _HitTile(hit: state.results[i], query: state.query.trim()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.query});
  final SearchHit hit;
  final String query;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(
        QuranRoutes.readerFromAyah(hit.ref.surah, hit.ref.ayah),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${hit.ref.surah}:${hit.ref.ayah}',
                    style: TextStyle(
                      color: AppColorsLight.primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.menu_book_outlined,
                    size: 14.r, color: context.brand.muted),
              ],
            ),
            SizedBox(height: 6.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: _HighlightedAyah(text: hit.snippet, query: query),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders Arabic ayah text with substring matches of [query] highlighted.
/// Matching is diacritic-tolerant: we normalise both sides, then map normalised
/// indices back onto the original string by walking runes in parallel.
class _HighlightedAyah extends StatelessWidget {
  const _HighlightedAyah({required this.text, required this.query});
  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans();
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 18.sp,
          height: 1.8,
          color: context.brand.onSurface,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _buildSpans() {
    final normQuery = DSLocalQuran.normaliseForSearch(query);
    if (normQuery.isEmpty) return [TextSpan(text: text)];

    // Build a parallel mapping: for each rune index in the original, what is
    // its index in the normalised version (or null if the rune was stripped)?
    final originalRunes = text.runes.toList();
    final normaliseMap = <int, int>{}; // original-rune-index → normalised-rune-index
    final normBuf = StringBuffer();
    for (int i = 0; i < originalRunes.length; i++) {
      final normalised = DSLocalQuran.normaliseForSearch(
        String.fromCharCode(originalRunes[i]),
      );
      if (normalised.isEmpty) continue;
      normaliseMap[i] = normBuf.length;
      normBuf.write(normalised);
    }
    final norm = normBuf.toString();
    final invMap = <int, int>{}; // normalised-rune-index → original-rune-index
    normaliseMap.forEach((orig, nrm) => invMap[nrm] = orig);

    final spans = <TextSpan>[];
    int cursor = 0;
    int searchFrom = 0;
    while (true) {
      final hit = norm.indexOf(normQuery, searchFrom);
      if (hit < 0) break;
      final origStart = invMap[hit];
      final origEnd = invMap[hit + normQuery.length] ?? originalRunes.length;
      if (origStart == null) {
        searchFrom = hit + normQuery.length;
        continue;
      }
      if (origStart > cursor) {
        spans.add(TextSpan(
          text: String.fromCharCodes(originalRunes.sublist(cursor, origStart)),
        ));
      }
      spans.add(TextSpan(
        text: String.fromCharCodes(originalRunes.sublist(origStart, origEnd)),
        style: TextStyle(
          color: AppColorsLight.primary,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColorsLight.primary.withValues(alpha: 0.12),
        ),
      ));
      cursor = origEnd;
      searchFrom = hit + normQuery.length;
    }
    if (cursor < originalRunes.length) {
      spans.add(TextSpan(
        text: String.fromCharCodes(originalRunes.sublist(cursor)),
      ));
    }
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}
