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
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_list_tile.dart';

class SNSurahList extends StatefulWidget {
  const SNSurahList({super.key});

  @override
  State<SNSurahList> createState() => _SNSurahListState();
}

class _SNSurahListState extends State<SNSurahList> {
  late final CBSurahList _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBSurahList>()..loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: context.brand.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              SizedBox(height: 8.h),
              _SearchAndFilters(cubit: _cubit),
              SizedBox(height: 12.h),
              Expanded(
                child: BlocBuilder<CBSurahList, SSurahList>(
                  builder: (context, state) {
                    if (state.status == LoadStatus.loading && state.all.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == LoadStatus.error) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            state.error ?? 'common_error'.tr(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final visible = state.visible;
                    if (visible.isEmpty) {
                      return Center(child: Text('search_no_results'.tr()));
                    }
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1.h,
                        color: context.brand.border,
                      ),
                      itemBuilder: (context, i) {
                        final surah = visible[i];
                        return WSurahListTile(
                          surah: surah,
                          onTap: () => Modular.to.pushNamed(
                            QuranRoutes.readerFromPage(surah.pageStart),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<CBSurahList, SSurahList>(
          buildWhen: (a, b) => a.lastRead != b.lastRead,
          builder: (context, state) {
            final lastRead = state.lastRead;
            if (lastRead == null) return const SizedBox();
            return FloatingActionButton.extended(
              backgroundColor: AppColorsLight.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                Modular.to.pushNamed(QuranRoutes.readerFromPage(lastRead.page));
              },
              icon: const Icon(Icons.bookmark_rounded),
              label: Text('surah_list_continue'.tr()),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Row(
        children: [
          Text(
            'القرآن الكريم',
            style: GoogleFonts.amiri(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.primaryDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppColorsLight.primary),
            tooltip: 'reciter_picker_title'.tr(),
            onPressed: () => Modular.to.pushNamed('${RoutesNames.quranBase}reciter'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: AppColorsLight.primary),
            tooltip: 'bookmarks_title'.tr(),
            onPressed: () => Modular.to.pushNamed('${RoutesNames.quranBase}bookmarks'),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColorsLight.primary),
            tooltip: 'downloads_title'.tr(),
            onPressed: () => Modular.to.pushNamed('${RoutesNames.quranBase}downloads'),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.cubit});
  final CBSurahList cubit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          TextField(
            onChanged: cubit.setQuery,
            decoration: InputDecoration(
              hintText: 'search_hint'.tr(),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.brand.border),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          BlocBuilder<CBSurahList, SSurahList>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) {
              return Row(
                children: [
                  _FilterChip(
                    label: 'common_all'.tr(),
                    active: state.filter == SurahFilter.all,
                    onTap: () => cubit.setFilter(SurahFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'surah_list_filter_makki'.tr(),
                    active: state.filter == SurahFilter.makki,
                    onTap: () => cubit.setFilter(SurahFilter.makki),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'surah_list_filter_madani'.tr(),
                    active: state.filter == SurahFilter.madani,
                    onTap: () => cubit.setFilter(SurahFilter.madani),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? AppColorsLight.primary : context.brand.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: active ? AppColorsLight.primary : context.brand.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : context.brand.onSurface,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
