import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';

/// Bottom sheet to switch reciter from inside the player. Selecting one applies
/// to the next ayah — [CBReciter.setActiveReciter] routes it to the player.
class WReciterSheet extends StatelessWidget {
  const WReciterSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = Modular.get<CBReciter>();
    if (cubit.state.all.isEmpty) cubit.load();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WReciterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBReciter>();
    return BlocProvider.value(
      value: cubit,
      child: Container(
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.brand.border,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'player_reciter'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: BlocBuilder<CBReciter, SReciter>(
                    builder: (context, state) {
                      if (state.all.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(24.h),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.all.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: context.brand.border),
                        itemBuilder: (context, i) {
                          final r = state.all[i];
                          final active = state.activeId == r.id;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                            ),
                            title: Text(
                              r.arabic.isNotEmpty ? r.arabic : r.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              r.name,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: context.brand.muted,
                              ),
                            ),
                            trailing: active
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColorsLight.primary,
                                    size: 22.r,
                                  )
                                : null,
                            onTap: () {
                              cubit.setActiveReciter(r.id);
                              Navigator.of(context).pop();
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
        ),
      ),
    );
  }
}
