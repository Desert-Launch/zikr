import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
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
  void dispose() {
    // The cubit is app-wide, so nothing else would end a sample left playing
    // when the user leaves the picker.
    _cubit.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<CBReciter, SReciter>(
        listenWhen: (a, b) => b.previewFailures > a.previewFailures,
        listener: (_, _) => AppAlert.error('reciter_preview_failed'.tr()),
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
                    if (state.status == LoadStatus.loading &&
                        state.all.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: state.all.length,
                      itemBuilder: (context, i) {
                        final r = state.all[i];
                        final previewing = state.previewingId == r.id;
                        return WReciterTile(
                          reciter: r,
                          isActive: state.activeId == r.id,
                          isPreviewing: previewing,
                          previewLoading: previewing && state.previewLoading,
                          previewDuration: previewing
                              ? state.previewDuration
                              : null,
                          onTap: () => _cubit.setActiveReciter(r.id),
                          onPreview: () => _cubit.togglePreview(r.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
