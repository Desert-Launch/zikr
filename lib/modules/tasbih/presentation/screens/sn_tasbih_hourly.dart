import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

/// Lets the user enable / disable the hourly tasbih notifications. The
/// schedule (08:00–22:00, silent channel) is fixed; only the on/off bit is
/// editable.
class SNTasbihHourly extends StatelessWidget {
  const SNTasbihHourly({super.key});

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBTasbih>();
    return BlocProvider.value(
      value: cb,
      child: WSharedScaffold(
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            WGradientAppBar(title: 'tasbih_hourly_title'.tr()),
            Expanded(
              child: BlocBuilder<CBTasbih, STasbih>(
                builder: (context, state) {
                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    children: [
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        elevation: 0,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                'tasbih_hourly_enable'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'tasbih_hourly_hint'.tr(),
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              value: state.hourlyEnabled,
                              onChanged: (v) async {
                                if (v) {
                                  final granted =
                                      await Modular.get<NotificationsService>()
                                          .requestPermission();
                                  if (!granted) return;
                                }
                                await cb.setHourlyEnabled(v);
                              },
                            ),
                            Divider(height: 1.h),
                            SwitchListTile(
                              title: Text(
                                'tasbih_vibrate'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'tasbih_vibrate_hint'.tr(),
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              value: state.vibrate,
                              onChanged: cb.setVibrate,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                        child: Text(
                          'tasbih_hourly_explainer'.tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.brand.muted,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
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
