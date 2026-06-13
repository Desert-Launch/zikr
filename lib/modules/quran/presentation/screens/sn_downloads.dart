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
import 'package:quran/modules/quran/presentation/widgets/w_downloads_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_downloads_list_body.dart';

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
                WDownloadsHeader(state: state, cubit: _cubit),
                Expanded(child: WDownloadsListBody(state: state, cubit: _cubit)),
              ],
            );
          },
        ),
      ),
    );
  }
}
