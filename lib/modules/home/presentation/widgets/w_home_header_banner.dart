import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_header_button.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_prayer_card.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_verse_card.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

/// Full-width green home header with the prayer and verse cards layered over it.
class WHomeHeaderBanner extends StatelessWidget {
  const WHomeHeaderBanner({super.key, required this.green, required this.gold});

  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final cardsTop = topInset + 62.h;
    final headerHeight = cardsTop + 320.h;

    // Composed leading-first (title, then the action buttons), so it reads
    // title-right/icons-left in Arabic and mirrors on its own in English —
    // it used to pin itself to RTL, which fought the app-wide direction.
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D7E5E), Color(0xFF0A6349)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30.r),
              ),
            ),
          ),
        ),
        Positioned(
          top: topInset + 8.h,
          left: 18.w,
          right: 18.w,
          child: SizedBox(
            height: 42.h,
            child: Row(
              children: [
                Text(
                  'home_page_title'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                BlocBuilder<CBAuth, SAuth>(
                  bloc: Modular.get<CBAuth>(),
                  builder: (_, state) => WHomeHeaderButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () => Modular.to.pushNamed(
                      state.isLoggedIn
                          ? SettingsRoutes.fullMain()
                          : AuthRoutes.fullLogin(),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                WHomeHeaderButton(
                  icon: Icons.settings_outlined,
                  onTap: () => Modular.to.pushNamed(SettingsRoutes.fullMain()),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, cardsTop, 20.w, 0),
          child: Column(
            children: [
              BlocBuilder<CBPrayerTimes, SPrayerTimes>(
                builder: (_, state) =>
                    WHomePrayerCard(state: state, green: green),
              ),
              SizedBox(height: 16.h),
              WHomeVerseCard(gold: gold),
            ],
          ),
        ),
      ],
    );
  }
}
