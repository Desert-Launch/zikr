import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/core/widgets/w_search_field.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';

class WQuranHeader extends StatelessWidget {
  const WQuranHeader({
    super.key,
    required this.cubit,
    required this.onBack,
    this.onSettings,
    this.onQueryChanged,
  });

  final CBSurahList cubit;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  /// Overrides the default `cubit.setQuery` — used to fan the query out to both
  /// the surah filter and the ayah search at once.
  final ValueChanged<String>? onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF007A58),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back leads, settings trails — mirrors with the layout direction
            // instead of being pinned to physical sides.
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const WLocalizeRotation(
                    reverse: true,
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'app_name'.tr(),
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'quran_surah_total'.tr(),
                        style: AppTextStyles.white12W400,
                      ),
                    ],
                  ),
                ),
                if (onSettings != null)
                  IconButton(
                    onPressed: onSettings,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  )
                else
                  const SizedBox(width: 42),
              ],
            ),
            SizedBox(height: 8.h),
            // Shared search field — direction-aware, so the hint and caret
            // follow the active language instead of the device locale.
            WSearchField.onColor(onChanged: onQueryChanged ?? cubit.setQuery),
          ],
        ),
      ),
    );
  }
}
