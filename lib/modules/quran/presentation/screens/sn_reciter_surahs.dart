import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter_surahs.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter_surahs.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_download_all_button.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_download_tile.dart';

/// The 114-surah download screen for a single reciter.
class SNReciterSurahs extends StatefulWidget {
  const SNReciterSurahs({required this.reciterId, super.key});

  final String reciterId;

  @override
  State<SNReciterSurahs> createState() => _SNReciterSurahsState();
}

class _SNReciterSurahsState extends State<SNReciterSurahs> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBReciterSurahs _cubit;
  String _title = '';

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBReciterSurahs>()..load(widget.reciterId);
    _resolveTitle();
  }

  Future<void> _resolveTitle() async {
    final res = await Modular.get<UCGetReciters>()();
    if (!mounted) return;
    res.fold((_) {}, (list) {
      final r = list.where((e) => e.id == widget.reciterId).firstOrNull;
      if (r != null) {
        setState(() => _title = r.arabic.isEmpty ? r.name : r.arabic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: WGradientAppBar(
          title: _title.isEmpty ? 'quran_downloads_title'.tr() : _title,
        ),
        body: BlocBuilder<CBReciterSurahs, SReciterSurahs>(
          builder: (context, state) {
            if (state.status == LoadStatus.loading && state.surahs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                _Header(state: state, cubit: _cubit),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                    itemCount: state.surahs.length,
                    itemBuilder: (context, i) {
                      final surah = state.surahs[i];
                      final info =
                          state.infoBySurah[surah.number] ??
                          SurahDownloadInfo(
                            surahNumber: surah.number,
                            downloaded: 0,
                            total: surah.totalAyah,
                          );
                      return WSurahDownloadTile(
                        surah: surah,
                        info: info,
                        progress: state.progressBySurah[surah.number],
                        onDownload: () => _cubit.downloadSurah(surah.number),
                        onDelete: () => _cubit.deleteSurah(surah.number),
                      );
                    },
                  ),
                ),
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
  final SReciterSurahs state;
  final CBReciterSurahs cubit;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final complete =
        state.stats?.downloadedSurahs ??
        state.infoBySurah.values.where((i) => i.isComplete).length;
    final mb = (state.stats?.totalBytes ?? 0) / 1024 / 1024;
    final summaryParts = <String>[
      '$complete/114 ${'quran_downloads_surahs_unit'.tr()}',
      if (mb > 0) '${mb.toStringAsFixed(0)} ${'quran_downloads_mb'.tr()}',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'quran_downloads_downloaded_label'.tr()}: ${summaryParts.join(' · ')}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: brand.muted,
            ),
          ),
          SizedBox(height: 10.h),
          WDownloadAllButton(
            isDownloadingAll: state.isDownloadingAll,
            currentSurah: state.allCurrentSurah,
            onDownloadAll: cubit.downloadAll,
            onCancel: cubit.cancelAll,
          ),
        ],
      ),
    );
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
