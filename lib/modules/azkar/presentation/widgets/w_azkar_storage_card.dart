import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';

/// مساحة الأصوات — total storage used by downloaded adhkar audio, broken down
/// per reader, with the one destructive action kept behind a confirmation.
///
/// Hidden entirely when nothing is downloaded: an empty storage panel is noise
/// on a screen whose job is to get the first pack downloaded.
class WAzkarStorageCard extends StatelessWidget {
  const WAzkarStorageCard({
    required this.usage,
    required this.readers,
    required this.onDeleteAll,
    super.key,
  });

  final AzkarStorageUsage usage;
  final List<MAzkarReader> readers;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    if (usage.isEmpty) return const SizedBox.shrink();
    final brand = context.brand;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';

    final rows = usage.perReader.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: brand.surfaceMuted,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: brand.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sd_storage_outlined, size: 18.r, color: brand.muted),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'azkar_audio_storage_title'.tr(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: brand.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${usage.totalMegabytes.toStringAsFixed(1)} '
                  '${'azkar_audio_mb'.tr()}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: brand.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            for (final row in rows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nameFor(row.key, isArabic),
                        style: TextStyle(fontSize: 12.sp, color: brand.muted),
                      ),
                    ),
                    Text(
                      '${(row.value / 1024 / 1024).toStringAsFixed(1)} '
                      '${'azkar_audio_mb'.tr()}',
                      style: TextStyle(fontSize: 12.sp, color: brand.muted),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 6.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onDeleteAll,
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  size: 18.r,
                  color: brand.error,
                ),
                label: Text(
                  'azkar_audio_delete_all'.tr(),
                  style: TextStyle(fontSize: 12.sp, color: brand.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nameFor(String readerId, bool isArabic) {
    for (final reader in readers) {
      if (reader.id == readerId) return reader.displayName(isArabic);
    }
    return readerId;
  }
}
