import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/models/m_download_task.dart';

class WDownloadProgressTile extends StatelessWidget {
  const WDownloadProgressTile({
    required this.title,
    required this.subtitle,
    required this.task,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    super.key,
  });

  final String title;
  final String subtitle;
  final MDownloadTask? task;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final isDone = t != null && t.isDone;
    final isActive = t != null && t.isActive;

    return ListTile(
      title: Text(title,
          style: GoogleFonts.amiri(fontSize: 16.sp, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitle, style: TextStyle(fontSize: 12.sp)),
          if (isActive) ...[
            SizedBox(height: 6.h),
            LinearProgressIndicator(
              value: t.progress,
              minHeight: 4.h,
              backgroundColor: context.brand.border,
              color: AppColorsLight.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              '${t.downloadedAyat}/${t.totalAyat} · ${(t.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
              style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
            ),
          ],
        ],
      ),
      trailing: isDone
          ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete)
          : isActive
              ? IconButton(icon: const Icon(Icons.stop_circle_outlined), onPressed: onCancel)
              : IconButton(
                  icon: const Icon(Icons.download_outlined, color: AppColorsLight.primary),
                  onPressed: onDownload,
                ),
    );
  }
}
