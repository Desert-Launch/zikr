import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_results.dart';

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
            const Expanded(child: WSearchResults()),
          ],
        ),
      ),
    );
  }
}
