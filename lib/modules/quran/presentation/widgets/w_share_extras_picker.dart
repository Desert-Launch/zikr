import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_book_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_section.dart';

/// "Extra content" — the tafsir books sent along with the verses.
///
/// The rows here are what is already attached; the whole catalogue, downloaded
/// or not, lives one tap away in [WShareBookPicker].
class WShareExtrasPicker extends StatelessWidget {
  const WShareExtrasPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBAyahShare>(context);
    return BlocSelector<
      CBAyahShare,
      SAyahShare,
      ({List<String> attached, List<ETafsirBook> available})
    >(
      selector: (s) => (attached: s.bookIds, available: s.availableBooks),
      builder: (context, books) {
        final attached = [
          for (final id in books.attached)
            TafsirCatalog.byIdOrPlaceholder(id),
        ];
        return WShareSection(
          label: 'quran_share_extras'.tr(),
          children: [
            if (attached.isNotEmpty) ...[
              // The order of this list is the order the books are printed in,
              // so it is worth being able to change — with the handles hidden
              // while there is only one book and nothing to arrange.
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: attached.length > 1,
                onReorder: cubit.reorderBooks,
                children: [
                  for (final book in attached)
                    _AttachedBook(
                      key: ValueKey(book.id),
                      book: book,
                      onRemove: () => cubit.removeBook(book.id),
                    ),
                ],
              ),
              const WShareRowDivider(),
            ],
            _AddRow(cubit: cubit),
          ],
        );
      },
    );
  }
}

class _AttachedBook extends StatelessWidget {
  const _AttachedBook({
    required this.book,
    required this.onRemove,
    super.key,
  });

  final ETafsirBook book;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return WShareRow(
      title: book.name,
      subtitle: book.language,
      leading: Icon(
        Icons.auto_stories_rounded,
        size: 18.r,
        color: context.brand.muted,
      ),
      trailing: IconButton(
        onPressed: onRemove,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
        tooltip: 'quran_share_remove_book'.tr(),
        icon: Icon(
          Icons.remove_circle_rounded,
          size: 20.r,
          color: context.brand.error,
        ),
      ),
    );
  }
}

/// The row that opens the catalogue.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.cubit});

  final CBAyahShare cubit;

  @override
  Widget build(BuildContext context) {
    return WShareRow(
      title: 'quran_share_add_book'.tr(),
      titleColor: context.brand.primary,
      onTap: () => WShareBookPicker.show(context, cubit),
      leading: Icon(Icons.add_rounded, size: 18.r, color: context.brand.primary),
    );
  }
}
