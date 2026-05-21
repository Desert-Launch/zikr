import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_ayah_action_sheet.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mini_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page.dart';

class SNMushafReader extends StatefulWidget {
  const SNMushafReader({super.key, this.initialPage, this.initialAyah});

  final int? initialPage;
  final ({int surah, int ayah})? initialAyah;

  @override
  State<SNMushafReader> createState() => _SNMushafReaderState();
}

class _SNMushafReaderState extends State<SNMushafReader> {
  late final CBMushafReader _cubit = Modular.get<CBMushafReader>();
  late final PageController _pageController;
  int _resolvedStart = 1;

  @override
  void initState() {
    super.initState();
    _resolvedStart = widget.initialPage ?? 1;
    _pageController = PageController(initialPage: _resolvedStart - 1, viewportFraction: 1);
    _resolveInitial();
  }

  Future<void> _resolveInitial() async {
    int target = widget.initialPage ?? 1;
    final initialAyah = widget.initialAyah;
    if (initialAyah != null) {
      target = await Modular.get<DSLocalQuran>().pageOfAyah(initialAyah.surah, initialAyah.ayah);
      if (mounted) {
        _pageController.jumpToPage(target - 1);
      }
    }
    _cubit.openPage(target);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _scrollToPlayingPage(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(ref.surah, ref.ayah);
    if (!mounted) return;
    if (_pageController.hasClients && _pageController.page?.round() != page - 1) {
      _pageController.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: AppColors.paperWarm,
        padding: EdgeInsets.zero,
        body: BlocListener<CBAudioPlayer, SAudioPlayer>(
          bloc: Modular.get<CBAudioPlayer>(),
          listenWhen: (a, b) => a.currentAyah?.key != b.currentAyah?.key,
          listener: (context, audio) {
            final ayah = audio.currentAyah;
            if (ayah != null) _scrollToPlayingPage(ayah);
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                reverse: true, // RTL — page 1 on the right
                itemCount: 604,
                onPageChanged: (i) => _cubit.openPage(i + 1),
                itemBuilder: (context, i) {
                  final pageNumber = i + 1;
                  return _PageLoader(pageNumber: pageNumber);
                },
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4.h,
                right: 8.w,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Modular.to.pop(),
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [WAyahActionSheet(), WMiniPlayer()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageLoader extends StatefulWidget {
  const _PageLoader({required this.pageNumber});
  final int pageNumber;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBMushafReader, SMushafReader>(
      buildWhen: (a, b) =>
          a.currentPage != b.currentPage ||
          a.status != b.status ||
          a.layout?.page != b.layout?.page,
      builder: (context, state) {
        final isCurrent = state.currentPage == widget.pageNumber;
        if (isCurrent && state.layout?.page == widget.pageNumber) {
          return WMushafPage(layout: state.layout!);
        }
        if (isCurrent && state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        // For non-current pages we don't have layout cached — render nothing
        // (PageView preloads neighbour widgets but they're never visible
        // until swiped; openPage() fires when the swipe completes).
        return const SizedBox.shrink();
      },
    );
  }
}
