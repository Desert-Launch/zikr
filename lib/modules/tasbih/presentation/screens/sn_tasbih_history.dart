import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';

class SNTasbihHistory extends StatelessWidget {
  const SNTasbihHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Modular.get<BoxTasbihHistory>();
    return Scaffold(
      appBar: AppBar(
        title: Text('tasbih_history'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'common_delete'.tr(),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('tasbih_clear_history'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('common_cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColorsLight.error,
                      ),
                      child: Text('common_delete'.tr()),
                    ),
                  ],
                ),
              );
              if (ok == true) await box.clearAll();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable,
        builder: (context, _, __) {
          final list = box.all().toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
          if (list.isEmpty) {
            return Center(
              child: Text('tasbih_history_empty'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp, color: context.brand.muted,
                  )),
            );
          }
          return Column(
            children: [
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  children: [
                    Text('tasbih_today_total'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.sp,
                        )),
                    SizedBox(height: 4.h),
                    Text('${box.totalToday()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1.h, color: context.brand.border),
                  itemBuilder: (_, i) {
                    final h = list[i];
                    return ListTile(
                      title: Text(h.zekrAr,
                          style: GoogleFonts.amiri(
                            fontSize: 16.sp, fontWeight: FontWeight.w600,
                          )),
                      subtitle: Text(_formatDate(h.completedAt),
                          style: TextStyle(
                            fontSize: 11.sp, color: context.brand.muted,
                          )),
                      trailing: Text('×${h.count}',
                          style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w800,
                            color: AppColorsLight.primary,
                          )),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
