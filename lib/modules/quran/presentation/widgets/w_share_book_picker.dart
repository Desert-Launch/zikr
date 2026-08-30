import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';

/// The whole tafsir catalogue, offered to a share.
///
/// Books already on the device attach on a tap; the rest download first and
/// attach when they land. Sending the reader off to the library to fetch one
/// would cost them the range and the choices they had already made here.
class WShareBookPicker extends StatelessWidget {
  const WShareBookPicker({super.key});

  static Future<void> show(BuildContext context, CBAyahShare cubit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.brand.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => BlocProvider<CBAyahShare>.value(
        value: cubit,
        child: const WShareBookPicker(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBAyahShare>(context);
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
            child: Text(
              'quran_share_add_book'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: context.brand.onSurface,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CBAyahShare, SAyahShare>(
              builder: (context, state) {
                // Downloaded books first: the ones that cost nothing to attach
                // are the ones most readers are looking for.
                final books = [
                  ...TafsirCatalog.books.where((b) => state.isDownloaded(b.id)),
                  ...TafsirCatalog.books.where((b) => !state.isDownloaded(b.id)),
                ];
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) => _BookTile(
                    book: books[index],
                    state: state,
                    onTap: () => _pick(context, cubit, books[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    CBAyahShare cubit,
    ETafsirBook book,
  ) async {
    final state = cubit.state;
    if (state.bookIds.contains(book.id) || state.isDownloading(book.id)) return;
    // A downloaded book attaches at once; a fetched one keeps the picker open
    // so its progress is visible, and closes it when it has landed.
    if (state.isDownloaded(book.id)) {
      await cubit.addBook(book);
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    final added = await cubit.downloadAndAddBook(book);
    if (added && context.mounted) Navigator.of(context).pop();
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.state,
    required this.onTap,
  });

  final ETafsirBook book;
  final SAyahShare state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attached = state.bookIds.contains(book.id);
    final downloaded = state.isDownloaded(book.id);
    final downloading = state.isDownloading(book.id);
    return Material(
      color: context.brand.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: attached || downloading ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 20.r,
                    color: downloaded
                        ? context.brand.primary
                        : context.brand.muted,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.brand.onSurface,
                          ),
                        ),
                        if (book.language.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            book.language,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.brand.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _Trailing(
                    attached: attached,
                    downloaded: downloaded,
                    downloading: downloading,
                  ),
                ],
              ),
              if (downloading) ...[
                SizedBox(height: 10.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: state.progressFor(book.id),
                    minHeight: 4.h,
                    backgroundColor: context.brand.surfaceMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.attached,
    required this.downloaded,
    required this.downloading,
  });

  final bool attached;
  final bool downloaded;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    if (downloading) {
      return SizedBox(
        width: 20.r,
        height: 20.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (attached) {
      return Icon(
        Icons.check_circle_rounded,
        size: 20.r,
        color: context.brand.success,
      );
    }
    return Icon(
      downloaded ? Icons.add_rounded : Icons.download_rounded,
      size: 20.r,
      color: context.brand.primary,
    );
  }
}
