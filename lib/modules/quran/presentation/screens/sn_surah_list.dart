import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';

class SNSurahList extends StatefulWidget {
  const SNSurahList({super.key});

  @override
  State<SNSurahList> createState() => _SNSurahListState();
}

class _SNSurahListState extends State<SNSurahList> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBSurahList _cubit = Modular.get<CBSurahList>()..loadInitial();

  void _goBack() {
    if (Modular.to.canPop()) {
      Modular.to.pop();
    } else {
      Modular.to.navigate(RoutesNames.homeBase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: PopScope(
        canPop: Modular.to.canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Modular.to.navigate(RoutesNames.homeBase);
        },
        child: Scaffold(
          backgroundColor: _canvas,
          body: BlocBuilder<CBSurahList, SSurahList>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _QuranHeader(cubit: _cubit, onBack: _goBack),
                  ),
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      cubit: _cubit,
                      state: state,
                      green: _green,
                    ),
                  ),
                  if (state.status == LoadStatus.loading && state.all.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == LoadStatus.error)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(state.error ?? 'common_error'.tr()),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _SummaryCards(
                        surahs: state.all.length,
                        ayat: state.all.fold(
                          0,
                          (sum, surah) => sum + surah.totalAyah,
                        ),
                        bookmarks: state.bookmarkCount,
                        green: _green,
                        gold: _gold,
                        onBookmarks: () =>
                            Modular.to.pushNamed(QuranRoutes.fullBookmarks()),
                      ),
                    ),
                    if (state.visible.isEmpty)
                      SliverFillRemaining(
                        child: Center(child: Text('search_no_results'.tr())),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                        sliver: SliverList.separated(
                          itemCount: state.visible.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (_, index) {
                            final surah = state.visible[index];
                            return _SurahCard(
                              surah: surah,
                              green: _green,
                              gold: _gold,
                              onTap: () => Modular.to.pushNamed(
                                QuranRoutes.readerFromPage(surah.pageStart),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuranHeader extends StatelessWidget {
  const _QuranHeader({required this.cubit, required this.onBack});

  final CBSurahList cubit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: _SNSurahListState._green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 42),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      'app_name'.tr(),
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'quran_surah_total'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextField(
              onChanged: cubit.setQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11.sp,
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20.r,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.cubit,
    required this.state,
    required this.green,
  });

  final CBSurahList cubit;
  final SSurahList state;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _FilterButton(
            label:
                '${state.all.where((s) => s.isMadani).length}  '
                '${'surah_list_filter_madani'.tr()}',
            active: state.filter == SurahFilter.madani,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.madani),
          ),
          SizedBox(width: 7.w),
          _FilterButton(
            label:
                '${state.all.where((s) => s.isMakki).length}  '
                '${'surah_list_filter_makki'.tr()}',
            active: state.filter == SurahFilter.makki,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.makki),
          ),
          SizedBox(width: 7.w),
          _FilterButton(
            label: 'common_all'.tr(),
            active: state.filter == SurahFilter.all,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.all),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.active,
    required this.green,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color green;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: active ? green : const Color(0xFFF8F8F5),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: active ? green : const Color(0xFFDDE1DD)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.surahs,
    required this.ayat,
    required this.bookmarks,
    required this.green,
    required this.gold,
    required this.onBookmarks,
  });

  final int surahs;
  final int ayat;
  final int bookmarks;
  final Color green;
  final Color gold;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
      child: Row(
        children: [
          _SummaryCard(
            icon: Icons.bookmark_border_rounded,
            value: '$bookmarks',
            label: 'bookmarks_title'.tr(),
            color: green,
            onTap: onBookmarks,
          ),
          SizedBox(width: 8.w),
          _SummaryCard(
            icon: Icons.star_border_rounded,
            value: '$ayat',
            label: 'quran_ayah_label'.tr(),
            color: gold,
          ),
          SizedBox(width: 8.w),
          _SummaryCard(
            icon: Icons.menu_book_outlined,
            value: '$surahs',
            label: 'quran_surah_label'.tr(),
            color: green,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 19.r),
              SizedBox(height: 12.h),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 13.sp),
              ),
              SizedBox(height: 5.h),
              Text(
                label,
                style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.green,
    required this.gold,
    required this.onTap,
  });

  final MSurah surah;
  final Color green;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = surah.isMakki ? green : gold;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _StarNumber(number: surah.number, green: green),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          surah.isMakki
                              ? 'surah_list_meccan'.tr()
                              : 'surah_list_medinan'.tr(),
                          style: TextStyle(color: typeColor, fontSize: 8.sp),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        surah.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${surah.name} · ${surah.totalAyah} '
                    '${'quran_ayah_label'.tr()}',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarNumber extends StatelessWidget {
  const _StarNumber({required this.number, required this.green});

  final int number;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42.r,
      height: 42.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: green.withValues(alpha: 0.18),
            size: 42.r,
          ),
          Text(
            '$number',
            style: TextStyle(
              color: green,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
