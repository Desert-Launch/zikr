import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_header.dart';
import 'package:quran/modules/home/presentation/widgets/w_shortcut_card.dart';

class SNHome extends StatelessWidget {
  const SNHome({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = <_Shortcut>[
      _Shortcut(
        icon: Icons.menu_book_rounded,
        labelKey: 'shortcut_quran',
        color: AppColorsLight.primary,
        route: RoutesNames.quranBase,
      ),
      _Shortcut(
        icon: Icons.mosque_rounded,
        labelKey: 'shortcut_prayer',
        color: AppColorsLight.accent,
        route: RoutesNames.prayerBase,
      ),
      _Shortcut(
        icon: Icons.format_list_bulleted_rounded,
        labelKey: 'shortcut_azkar',
        color: const Color(0xFF8B5CF6),
        route: RoutesNames.azkarBase,

      ),
      _Shortcut(
        icon: Icons.circle_outlined,
        labelKey: 'shortcut_tasbih',
        color: const Color(0xFF3B82F6),
        route: RoutesNames.tasbihBase,

      ),
      _Shortcut(
        icon: Icons.explore_rounded,
        labelKey: 'shortcut_qibla',
        color: const Color(0xFFEF4444),
        route: RoutesNames.qiblaBase,

      ),
      _Shortcut(
        icon: Icons.event_note_rounded,
        labelKey: 'shortcut_khatma',
        color: const Color(0xFF10B981),
        route: RoutesNames.khatmaBase,

      ),
      _Shortcut(
        icon: Icons.location_city_rounded,
        labelKey: 'shortcut_mosques',
        color: const Color(0xFFF59E0B),
        route: RoutesNames.mosquesBase,

      ),
      _Shortcut(
        icon: Icons.notifications_active_outlined,
        labelKey: 'shortcut_reminders',
        color: const Color(0xFFEC4899),
        route: RoutesNames.remindersBase,

      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const WHomeHeader(),
            SizedBox(height: 16.h),
            _ContinueReadingCard(),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'home_shortcuts'.tr(),
                style: GoogleFonts.tajawal(
                  fontSize: 14.sp, fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shortcuts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) {
                  final s = shortcuts[i];
                  return WShortcutCard(
                    icon: s.icon,
                    label: s.labelKey.tr(),
                    color: s.color,
                    onTap: () => Modular.to.pushNamed(s.route),
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.icon,
    required this.labelKey,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String labelKey;
  final Color color;
  final String route;
}

class _ContinueReadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Modular.to.pushNamed(RoutesNames.quranBase),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColorsLight.accent, Color(0xFFE8B547)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 30.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home_continue_reading'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'home_continue_reading_hint'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
