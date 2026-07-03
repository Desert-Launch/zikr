import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_tafsir.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/cubits/s_tafsir.dart';
import 'package:quran/modules/quran/presentation/widgets/w_tafsir_content.dart';

/// Per-ayah tafsir viewer. One tab per downloaded book.
class SNTafsir extends StatefulWidget {
  const SNTafsir({required this.ayah, super.key});

  final ParamAyahRef ayah;

  @override
  State<SNTafsir> createState() => _SNTafsirState();
}

class _SNTafsirState extends State<SNTafsir> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBTafsir _cubit = Modular.get<CBTafsir>()..load(widget.ayah);

  Future<void> _openLibrary() async {
    await Modular.to.pushNamed(QuranRoutes.fullTafsirLibrary());
    // Coming back may have added or removed books — refresh.
    _cubit.load(widget.ayah);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(
              title: 'tafsir_title'.tr(),
              subtitle: '${'quran_surah_label'.tr()} ${widget.ayah.surah} · '
                  '${'quran_ayah_label'.tr()} ${widget.ayah.ayah}',
              actions: [
                IconButton(
                  tooltip: 'tafsir_library_title'.tr(),
                  icon: const Icon(Icons.library_books_outlined, color: Colors.white),
                  onPressed: _openLibrary,
                ),
              ],
            ),
            Expanded(
              child: BlocBuilder<CBTafsir, STafsir>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!state.hasBooks) {
                    return _Prompt(
                      icon: Icons.library_books_outlined,
                      message: 'tafsir_no_books'.tr(),
                      buttonLabel: 'tafsir_browse_library'.tr(),
                      onPressed: _openLibrary,
                    );
                  }
                  if (state.entries.isEmpty) {
                    return _Prompt(
                      icon: Icons.menu_book_outlined,
                      message: 'tafsir_empty_for_ayah'.tr(),
                      buttonLabel: 'tafsir_browse_library'.tr(),
                      onPressed: _openLibrary,
                    );
                  }
                  return _TafsirTabs(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirTabs extends StatelessWidget {
  const _TafsirTabs({required this.state});
  final STafsir state;

  @override
  Widget build(BuildContext context) {
    final entries = state.entries;
    return DefaultTabController(
      length: entries.length,
      child: Column(
        children: [
          if (entries.length > 1)
            Material(
              color: _canvasSurface(context),
              child: TabBar(
                isScrollable: true,
                labelColor: context.brand.primary,
                unselectedLabelColor: context.brand.muted,
                indicatorColor: context.brand.primary,
                tabAlignment: TabAlignment.start,
                tabs: [for (final e in entries) Tab(text: e.book.name)],
              ),
            ),
          Expanded(
            child: TabBarView(
              children: [for (final e in entries) WTafsirContent(entry: e)],
            ),
          ),
        ],
      ),
    );
  }

  Color _canvasSurface(BuildContext context) => context.brand.surface;
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.brand.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46.r, color: context.brand.primary),
            ),
            SizedBox(height: 16.h),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.grey16W500),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.download_rounded),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(backgroundColor: context.brand.primary),
            ),
          ],
        ),
      ),
    );
  }
}
