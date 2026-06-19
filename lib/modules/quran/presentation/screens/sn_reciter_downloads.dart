import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_reciter_card.dart';

/// Reciter list of the download manager — pick a reciter to manage its surahs.
class SNReciterDownloads extends StatefulWidget {
  const SNReciterDownloads({super.key});

  @override
  State<SNReciterDownloads> createState() => _SNReciterDownloadsState();
}

class _SNReciterDownloadsState extends State<SNReciterDownloads> {
  static const _canvas = Color(0xFFF8F7F4);
  late final CBReciterDownloads _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBReciterDownloads>()..load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(title: 'quran_downloads_title'.tr()),
            Expanded(
              child: BlocBuilder<CBReciterDownloads, SReciterDownloads>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading &&
                      state.reciters.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == LoadStatus.error &&
                      state.reciters.isEmpty) {
                    return Center(
                      child: Text(state.error ?? 'common_error'.tr()),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    itemCount: state.reciters.length,
                    itemBuilder: (context, i) {
                      final reciter = state.reciters[i];
                      return WReciterCard(
                        reciter: reciter,
                        stats: state.stats[reciter.id],
                        onTap: () async {
                          await Modular.to.pushNamed(
                            QuranRoutes.reciterSurahsFor(reciter.id),
                          );
                          _cubit.refresh();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
