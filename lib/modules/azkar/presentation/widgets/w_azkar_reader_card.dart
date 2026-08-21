import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';

/// A reader row in the download manager: who they are, what they offer, how
/// much of it is on this device, and the one action that makes sense next.
///
/// Every number comes from the manifest and the filesystem — the card never
/// advertises adhkar the reader does not actually have.
class WAzkarReaderCard extends StatelessWidget {
  const WAzkarReaderCard({
    required this.reader,
    required this.stats,
    required this.progress,
    required this.isPreferred,
    required this.onTap,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    super.key,
  });

  final MAzkarReader reader;
  final AzkarReaderStats stats;
  final AzkarPackProgress? progress;
  final bool isPreferred;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final running = progress != null && !(progress?.isDone ?? true);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: Material(
        color: brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: isPreferred ? brand.primary : brand.border,
            width: isPreferred ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: brand.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        color: brand.primary,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  reader.displayName(isArabic),
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: brand.onSurface,
                                  ),
                                ),
                              ),
                              if (isPreferred) ...[
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.star_rounded,
                                  size: 16.r,
                                  color: brand.primary,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            reader.sourceName,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: brand.muted,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _offerLine(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: brand.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    WLocalizeRotation(
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: brand.muted,
                        size: 24.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                _StatusLine(
                  stats: stats,
                  progress: progress,
                  estimatedMb: reader.estimatedMegabytes,
                ),
                SizedBox(height: 8.h),
                if (running)
                  LinearProgressIndicator(
                    value: progress?.fraction,
                    minHeight: 4.h,
                    color: brand.primary,
                    backgroundColor: brand.border,
                  ),
                SizedBox(height: 8.h),
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
                              onPressed: stats.isComplete ? null : onDownload,
                              icon: Icon(
                                stats.isPartial
                                    ? Icons.play_arrow_rounded
                                    : Icons.download_rounded,
                                size: 16.r,
                              ),
                              label: Text(
                                stats.isComplete
                                    ? 'azkar_audio_downloaded'.tr()
                                    : stats.isPartial
                                    ? 'azkar_audio_resume'.tr()
                                    : 'azkar_audio_download_all'.tr(),
                              ),
                            ),
                    ),
                    if (!stats.isEmpty) ...[
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'azkar_audio_delete_files'.tr(),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20.r,
                          color: brand.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What this reader actually provides, in the user's terms.
  String _offerLine() {
    final parts = <String>[
      if (reader.mappedAdhkar > 0)
        '${reader.mappedAdhkar} ${'azkar_audio_unit_adhkar'.tr()}',
      if (reader.categoryRecordings > 0)
        '${reader.categoryRecordings} ${'azkar_audio_unit_sittings'.tr()}',
    ];
    if (reader.estimatedBytes > 0) {
      parts.add(
        '${reader.estimatedMegabytes.toStringAsFixed(0)} '
        '${'azkar_audio_mb'.tr()}',
      );
    }
    return parts.join(' · ');
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.stats,
    required this.progress,
    required this.estimatedMb,
  });

  final AzkarReaderStats stats;
  final AzkarPackProgress? progress;
  final double estimatedMb;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final p = progress;
    final running = p != null && !p.isDone;

    final String text;
    final Color color;
    if (running) {
      final percent = (p.fraction * 100).round();
      text =
          '${'azkar_audio_downloading'.tr()} '
          '${p.completed + p.failed} / ${p.total} · $percent%';
      color = brand.primary;
    } else if (stats.isComplete) {
      text =
          '${stats.downloaded} / ${stats.total} · '
          '${'azkar_audio_complete'.tr()}';
      color = brand.success;
    } else if (stats.isPartial) {
      final percent = (stats.fraction * 100).round();
      text =
          '${stats.downloaded} / ${stats.total} '
          '${'azkar_audio_downloaded_count'.tr()} · $percent%';
      color = brand.primary;
    } else {
      text = 'azkar_audio_not_downloaded'.tr();
      color = brand.muted;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (stats.bytesOnDisk > 0)
          Text(
            '${stats.megabytesOnDisk.toStringAsFixed(1)} '
            '${'azkar_audio_mb'.tr()}',
            style: TextStyle(fontSize: 11.sp, color: brand.muted),
          ),
      ],
    );
  }
}
