import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_reciter_tile.dart';

class SNReciterPicker extends StatefulWidget {
  const SNReciterPicker({super.key});

  @override
  State<SNReciterPicker> createState() => _SNReciterPickerState();
}

class _SNReciterPickerState extends State<SNReciterPicker> {
  late final CBReciter _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CBReciter>();
    if (_cubit.state.all.isEmpty) _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: context.brand.background,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(title: 'reciter_picker_title'.tr()),
            Expanded(
              child: BlocBuilder<CBReciter, SReciter>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading && state.all.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: state.all.length,
                    itemBuilder: (context, i) {
                      final r = state.all[i];
                      return WReciterTile(
                        reciter: r,
                        isActive: state.activeId == r.id,
                        isPreviewing: state.previewingId == r.id,
                        onTap: () => _cubit.setActiveReciter(r.id),
                        onPreview: () {
                          if (state.previewingId == r.id) {
                            _cubit.stopPreview();
                          } else {
                            _cubit.previewAyah(r.id);
                          }
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
