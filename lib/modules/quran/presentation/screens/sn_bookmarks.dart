import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_bookmarks.dart';

class SNBookmarks extends StatefulWidget {
  const SNBookmarks({super.key});

  @override
  State<SNBookmarks> createState() => _SNBookmarksState();
}

class _SNBookmarksState extends State<SNBookmarks> {
  late final CBBookmarks _cubit = Modular.get<CBBookmarks>()..load();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        appBar: Text(
          'bookmarks_title'.tr(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.brand.background,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBBookmarks, SBookmarks>(
          builder: (context, state) {
            if (state.all.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Text(
                    'bookmarks_empty'.tr(),
                    style: TextStyle(fontSize: 14.sp, color: context.brand.muted),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: state.all.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1.h, color: context.brand.border),
              itemBuilder: (context, i) {
                final b = state.all[i];
                return ListTile(
                  leading: const Icon(Icons.bookmark_rounded, color: AppColorsLight.primary),
                  title: Text(
                    'سورة ${b.surah} · آية ${b.ayah}',
                    style: GoogleFonts.amiri(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  subtitle: b.note == null
                      ? null
                      : Text(b.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _cubit.delete(b.id),
                  ),
                  onTap: () {
                    Modular.to.pushNamed(
                      '${RoutesNames.quranBase}reader?surah=${b.surah}&ayah=${b.ayah}',
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
