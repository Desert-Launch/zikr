import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_tafsir_library.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/cubits/s_tafsir_library.dart';
import 'package:quran/modules/quran/presentation/widgets/w_tafsir_book_tile.dart';

/// Browse the tafsir catalogue and download / delete books, grouped by language.
class SNTafsirLibrary extends StatefulWidget {
  const SNTafsirLibrary({super.key});

  @override
  State<SNTafsirLibrary> createState() => _SNTafsirLibraryState();
}

class _SNTafsirLibraryState extends State<SNTafsirLibrary> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBTafsirLibrary _cubit = Modular.get<CBTafsirLibrary>()..load();

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
              title: 'tafsir_library_title'.tr(),
              subtitle: 'tafsir_library_subtitle'.tr(),
            ),
            Expanded(
              child: BlocConsumer<CBTafsirLibrary, STafsirLibrary>(
                listenWhen: (prev, curr) => curr.error != null && prev.error != curr.error,
                listener: (context, state) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${'common_error'.tr()}: ${state.error}')),
                  );
                },
                builder: (context, state) {
                  if (state.status == LoadStatus.loading && state.books.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildList(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(STafsirLibrary state) {
    // Group catalogue by language, preserving catalogue order.
    final groups = <String, List<ETafsirBook>>{};
    for (final book in state.books) {
      groups.putIfAbsent(book.language, () => []).add(book);
    }
    final languages = groups.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: languages.length,
      itemBuilder: (context, i) {
        final lang = languages[i];
        final books = groups[lang] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, i == 0 ? 0 : 18.h, 4.w, 8.h),
              child: Text(lang, style: AppTextStyles.grey14W700),
            ),
            for (final book in books) ...[
              WTafsirBookTile(
                book: book,
                isDownloaded: state.isDownloaded(book.id),
                isDownloading: state.isDownloading(book.id),
                progress: state.progressFor(book.id),
                onDownload: () => _cubit.downloadBook(book),
                onDelete: () => _confirmDelete(book),
              ),
              SizedBox(height: 10.h),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(ETafsirBook book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tafsir_delete'.tr()),
        content: Text('tafsir_delete_confirm'.tr().replaceFirst('{{book}}', book.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common_cancel'.tr())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('tafsir_delete'.tr())),
        ],
      ),
    );
    if (ok == true) _cubit.deleteBook(book);
  }
}
