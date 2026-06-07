import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';

/// Green-gradient hero header on the home dashboard. Shows the user's name,
/// avatar, and a settings shortcut.
class WHomeHeader extends StatelessWidget {
  const WHomeHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home_greeting_morning'.tr();
    if (hour < 18) return 'home_greeting_afternoon'.tr();
    return 'home_greeting_evening'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: BlocBuilder<CBAuth, SAuth>(
        bloc: Modular.get<CBAuth>(),
        builder: (context, state) {
          final user = state.user;
          return Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Modular.to.pushNamed(
                  state.isLoggedIn
                      ? SettingsRoutes.fullMain()
                      : AuthRoutes.fullLogin(),
                ),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  backgroundImage: user?.avatar != null
                      ? NetworkImage(user!.avatar!)
                      : null,
                  child: user?.avatar == null
                      ? Icon(Icons.person, color: AppColorsLight.accent)
                      : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      user?.name ?? 'app_name'.tr(),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'settings_title'.tr(),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () =>
                    Modular.to.pushNamed(SettingsRoutes.fullMain()),
              ),
            ],
          );
        },
      ),
    );
  }
}
