import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_downloads.dart';
import 'package:quran/modules/quran/presentation/widgets/w_download_progress_tile.dart';

class WDownloadsListBody extends StatelessWidget {
  const WDownloadsListBody({super.key, required this.state, required this.cubit});
  final SDownloads state;
  final CBDownloads cubit;

  @override
  Widget build(BuildContext context) {
    final reciter = state.activeReciterId ?? '';
    if (state.groupBy == DownloadGroupBy.surah) {
      return ListView.builder(
        itemCount: state.surahs.length,
        itemBuilder: (context, i) {
          final s = state.surahs[i];
          final id = '${reciter}_surah_${s.number}';
          final task = state.tasks[id];
          return WDownloadProgressTile(
            title: '${s.number}. ${s.arabic}',
            subtitle: '${s.totalAyah} آية',
            task: task,
            onDownload: () => cubit.downloadSurah(s.number),
            onCancel: () => cubit.cancelTask(id),
            onDelete: () => cubit.deleteTask(id),
          );
        },
      );
    }
    // Juz grid
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, i) {
        final juz = i + 1;
        final id = '${reciter}_juz_$juz';
        final task = state.tasks[id];
        return WDownloadProgressTile(
          title: 'الجزء $juz',
          subtitle: '${'surah_list_juz'.tr()} $juz',
          task: task,
          onDownload: () => cubit.downloadJuz(juz),
          onCancel: () => cubit.cancelTask(id),
          onDelete: () => cubit.deleteTask(id),
        );
      },
    );
  }
}
