import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_player_bar.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_player_page.dart';

class SNAzkarPlayer extends StatefulWidget {
  const SNAzkarPlayer({super.key, required this.categoryId, this.itemIndex = 0});

  final String categoryId;
  final int itemIndex;

  @override
  State<SNAzkarPlayer> createState() => _SNAzkarPlayerState();
}

class _SNAzkarPlayerState extends State<SNAzkarPlayer> {
  static const _green = AppColorsLight.primary;
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBAzkarSession _cubit = Modular.get<CBAzkarSession>();
  late final PageController _pageController = PageController(initialPage: widget.itemIndex);

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Factory cubit owned by this screen — closing it also stops the
    // recitation and frees the shared media slot.
    _cubit.close();
    super.dispose();
  }

  Future<void> _open() async {
    await _cubit.open(widget.categoryId);
    if (!mounted) return;
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
            final current = _pageController.page?.round() ?? _pageController.initialPage;
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
            final current = state.currentItem;
            if (category == null || current == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                WGradientAppBar(
                  title: LocalizeAndTranslate.getLanguageCode() == 'ar' ? category.nameAr : category.nameEn,
                  subtitle: 'azkar_header_subtitle'.tr(),
                  centerTitle: false,
                  onBack: NavHelper.back,
                  actions: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: CircleAvatar(
                        radius: 21.r,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        child: const Text('🤲', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: category.items.length,
                    onPageChanged: _cubit.jumpTo,
                    itemBuilder: (_, index) =>
                        WAzkarPlayerPage(item: category.items[index], gold: _gold, onTap: _cubit.tap),
                  ),
                ),
                WAzkarPlayerBar(
                  completed: state.countFor(current.id),
                  total: current.repeat,
                  green: _green,
                  onTap: _cubit.tap,
                  onReset: _cubit.resetCurrent,
                  onPrevious: _cubit.previous,
                  onNext: _cubit.next,
                  onPlay: current.hasAudio ? _cubit.toggleAudio : null,
                  playing: state.audioPlaying,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
