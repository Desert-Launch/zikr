import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_header.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_counter_card.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_virtue_card.dart';

class SNAzkarPlayer extends StatefulWidget {
  const SNAzkarPlayer({
    super.key,
    required this.categoryId,
    this.itemIndex = 0,
  });

  final String categoryId;
  final int itemIndex;

  @override
  State<SNAzkarPlayer> createState() => _SNAzkarPlayerState();
}

class _SNAzkarPlayerState extends State<SNAzkarPlayer> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBAzkarSession _cubit = Modular.get<CBAzkarSession>();
  late final BoxAzkarFavorite _favorites = Modular.get<BoxAzkarFavorite>();
  late final PageController _pageController = PageController(
    initialPage: widget.itemIndex,
  );

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await _cubit.open(widget.categoryId);
    _cubit.jumpTo(widget.itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocConsumer<CBAzkarSession, SAzkarSession>(
          // Keep the pager in sync when the index changes elsewhere (e.g. the
          // auto-advance after completing a zekr).
          listenWhen: (prev, curr) => prev.itemIndex != curr.itemIndex,
          listener: (_, state) {
            if (!_pageController.hasClients) return;
            final current =
                _pageController.page?.round() ?? _pageController.initialPage;
            if (current != state.itemIndex) {
              _pageController.animateToPage(
                state.itemIndex,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
          },
          builder: (_, state) {
            final category = state.category;
            if (category == null || category.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                WAzkarHeader(
                  green: _green,
                  title: LocalizeAndTranslate.getLanguageCode() == 'ar'
                      ? category.nameAr
                      : category.nameEn,
                  categoryCount: category.items.length,
                  completedToday: category.items
                      .where((item) => state.isComplete(item))
                      .length,
                  favorites: _favorites.all().length,
                  onBack: Modular.to.pop,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: category.items.length,
                    onPageChanged: _cubit.jumpTo,
                    itemBuilder: (_, index) {
                      final item = category.items[index];
                      final completed = state.countFor(item.id);
                      final virtue = item.virtueAr;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 28.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WAzkarCounterCard(
                              item: item,
                              completed: completed,
                              green: _green,
                              onTap: _cubit.tap,
                              onReset: _cubit.resetCurrent,
                            ),
                            if (virtue != null && virtue.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              WAzkarVirtueCard(text: virtue, gold: _gold),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
