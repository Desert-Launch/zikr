import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio_downloads.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio_downloads.dart';

/// A single reader's pack, broken down by adhkar category.
///
/// Each row can be downloaded or removed on its own, so somebody who only ever
/// reads the morning and evening adhkar never has to fetch 174 MB to get them.
class SNAzkarReaderDetail extends StatefulWidget {
  const SNAzkarReaderDetail({super.key, required this.readerId});

  final String readerId;

  @override
  State<SNAzkarReaderDetail> createState() => _SNAzkarReaderDetailState();
}

class _SNAzkarReaderDetailState extends State<SNAzkarReaderDetail> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBAzkarAudioDownloads _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBAzkarAudioDownloads>();
    _cubit.loadCategories(widget.readerId);
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<CBAzkarAudioDownloads, SAzkarAudioDownloads>(
        builder: (context, state) {
          final reader = state.readerById(widget.readerId);
          final stats = state.statsFor(widget.readerId);
          final categories = state.categoriesFor(widget.readerId);
          final progress = state.progress[widget.readerId];
          final running = progress != null && !progress.isDone;

          return WSharedScaffold(
            backgroundColor: _canvas,
            withSafeArea: false,
            padding: EdgeInsets.zero,
            body: Column(
              children: [
                WGradientAppBar(
                  title:
                      reader?.displayName(isArabic) ??
                      'azkar_audio_downloads_title'.tr(),
                  subtitle: reader?.sourceName,
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                    children: [
                      _SummaryCard(
                        stats: stats,
                        progress: progress,
                        isPreferred: state.preferredReaderId == widget.readerId,
                        onMakePreferred: () =>
                            _cubit.setPreferredReader(widget.readerId),
                        onDownloadAll: () => _cubit.start(widget.readerId),
                        onCancel: () => _cubit.cancel(widget.readerId),
                        running: running,
                      ),
                      if (reader != null) ...[
                        SizedBox(height: 10.h),
                        _AttributionCard(
                          attribution: reader.attribution,
                          sourceUrl: reader.sourceUrl,
                        ),
                      ],
                      SizedBox(height: 14.h),
                      Text(
                        'azkar_audio_categories'.tr(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: context.brand.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (categories.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      for (final category in categories)
                        _CategoryRow(
                          info: category,
                          isArabic: isArabic,
                          busy: running,
                          onDownload: () => _cubit.start(
                            widget.readerId,
                            categoryId: category.categoryId,
                          ),
                          onDelete: () => _cubit.deleteCategory(
                            widget.readerId,
                            category.categoryId,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.stats,
    required this.progress,
    required this.isPreferred,
    required this.onMakePreferred,
    required this.onDownloadAll,
    required this.onCancel,
    required this.running,
  });

  final AzkarReaderStats stats;
  final AzkarPackProgress? progress;
  final bool isPreferred;
  final VoidCallback onMakePreferred;
  final VoidCallback onDownloadAll;
  final VoidCallback onCancel;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final p = progress;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${stats.downloaded} / ${stats.total}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: brand.onSurface,
                  ),
                ),
              ),
              Text(
                stats.bytesOnDisk > 0
                    ? '${stats.megabytesOnDisk.toStringAsFixed(1)} '
                          '${'azkar_audio_mb'.tr()}'
                    : '${stats.estimatedMegabytes.toStringAsFixed(0)} '
                          '${'azkar_audio_mb'.tr()}',
                style: TextStyle(fontSize: 13.sp, color: brand.muted),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: running ? p?.fraction : stats.fraction,
            minHeight: 5.h,
            color: brand.primary,
            backgroundColor: brand.border,
          ),
          if (running && p != null) ...[
            SizedBox(height: 6.h),
            Text(
              '${'azkar_audio_downloading'.tr()} '
              '${p.completed + p.failed} / ${p.total}'
              '${_byteLine(p)}',
              style: TextStyle(fontSize: 11.sp, color: brand.primary),
            ),
          ],
          if (stats.failed > 0 && !running) ...[
            SizedBox(height: 6.h),
            Text(
              '${stats.failed} ${'azkar_audio_failed_retry'.tr()}',
              style: TextStyle(fontSize: 11.sp, color: brand.error),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: running
                    ? OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: Icon(Icons.stop_rounded, size: 16.r),
                        label: Text('azkar_audio_cancel'.tr()),
                      )
                    : FilledButton.icon(
                        onPressed: stats.isComplete ? null : onDownloadAll,
                        icon: Icon(Icons.download_rounded, size: 16.r),
                        label: Text(
                          stats.isComplete
                              ? 'azkar_audio_downloaded'.tr()
                              : stats.isPartial
                              ? 'azkar_audio_resume'.tr()
                              : 'azkar_audio_download_all'.tr(),
                        ),
                      ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPreferred ? null : onMakePreferred,
                  icon: Icon(
                    isPreferred ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16.r,
                  ),
                  label: Text(
                    isPreferred
                        ? 'azkar_audio_is_preferred'.tr()
                        : 'azkar_audio_make_preferred'.tr(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Byte counter for the file in flight — only shown when the size is known.
  String _byteLine(AzkarPackProgress p) {
    if (p.currentTotalBytes <= 0) return '';
    final received = (p.currentBytes / 1024 / 1024).toStringAsFixed(1);
    final total = (p.currentTotalBytes / 1024 / 1024).toStringAsFixed(1);
    return ' · $received / $total ${'azkar_audio_mb'.tr()}';
  }
}

class _AttributionCard extends StatelessWidget {
  const _AttributionCard({required this.attribution, required this.sourceUrl});

  final String attribution;
  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: brand.surfaceMuted,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 16.r, color: brand.muted),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'azkar_audio_source'.tr(),
                  style: TextStyle(fontSize: 10.sp, color: brand.muted),
                ),
                Text(
                  attribution,
                  style: TextStyle(fontSize: 12.sp, color: brand.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.info,
    required this.isArabic,
    required this.busy,
    required this.onDownload,
    required this.onDelete,
  });

  final AzkarCategoryAudioInfo info;
  final bool isArabic;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: brand.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: brand.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          info.name(isArabic),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: brand.onSurface,
                          ),
                        ),
                      ),
                      if (info.hasCategoryRecording) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.album_outlined,
                          size: 13.r,
                          color: brand.muted,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${info.downloaded} / ${info.total}'
                    '${info.bytes > 0 ? ' · ${(info.bytes / 1024 / 1024).toStringAsFixed(1)} ${'azkar_audio_mb'.tr()}' : ''}',
                    style: TextStyle(fontSize: 11.sp, color: brand.muted),
                  ),
                ],
              ),
            ),
            if (info.isComplete)
              IconButton(
                onPressed: onDelete,
                tooltip: 'azkar_audio_delete_files'.tr(),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20.r,
                  color: brand.error,
                ),
              )
            else
              IconButton(
                onPressed: busy ? null : onDownload,
                tooltip: 'azkar_audio_download'.tr(),
                icon: Icon(
                  Icons.download_rounded,
                  size: 20.r,
                  color: busy ? brand.muted : brand.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
