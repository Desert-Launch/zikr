import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_downloads.dart';

class WDownloadsHeader extends StatelessWidget {
  const WDownloadsHeader({super.key, required this.state, required this.cubit});
  final SDownloads state;
  final CBDownloads cubit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          if (state.reciters.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: state.activeReciterId ?? state.reciters.first.id,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              items: state.reciters
                  .map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.arabic.isEmpty ? r.name : r.arabic),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null) cubit.setReciter(id);
              },
            ),
          SizedBox(height: 8.h),
          Row(
            children: [
              ChoiceChip(
                label: Text('downloads_by_surah'.tr()),
                selected: state.groupBy == DownloadGroupBy.surah,
                onSelected: (_) => cubit.setGroupBy(DownloadGroupBy.surah),
              ),
              SizedBox(width: 8.w),
              ChoiceChip(
                label: Text('downloads_by_juz'.tr()),
                selected: state.groupBy == DownloadGroupBy.juz,
                onSelected: (_) => cubit.setGroupBy(DownloadGroupBy.juz),
              ),
              const Spacer(),
              Text(
                '${(state.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
