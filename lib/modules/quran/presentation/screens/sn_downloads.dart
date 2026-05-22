import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_download_progress_tile.dart';

class SNDownloads extends StatefulWidget {
  const SNDownloads({super.key});

  @override
  State<SNDownloads> createState() => _SNDownloadsState();
}

class _SNDownloadsState extends State<SNDownloads> {
  late final CBDownloads _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBDownloads>()..load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        appBar: Text(
          'downloads_title'.tr(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.brand.background,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBDownloads, SDownloads>(
          builder: (context, state) {
            if (state.status == LoadStatus.loading && state.surahs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                _Header(state: state, cubit: _cubit),
                Expanded(child: _ListBody(state: state, cubit: _cubit)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.cubit});
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

class _ListBody extends StatelessWidget {
  const _ListBody({required this.state, required this.cubit});
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
