import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';
import 'package:quran/modules/settings/presentation/widgets/w_profile_avatar.dart';

class WProfileCard extends StatelessWidget {
  const WProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAuth, SAuth>(
      bloc: Modular.get<CBAuth>(),
      builder: (_, state) {
        final user = state.user;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19.r),
            border: Border.all(color: const Color(0xFFE2ECE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              WProfileAvatar(avatar: user?.avatar),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'settings_guest_user'.tr(),
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF2C2C2C),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: const Color(0xFF7C7C7C),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    InkWell(
                      onTap: () => Modular.to.pushNamed(AuthRoutes.fullLogin()),
                      child: Text(
                        'settings_edit_profile'.tr(),
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF2F7E63),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
