import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_login_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_login_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_header.dart';

class SNLogin extends StatefulWidget {
  const SNLogin({super.key});

  @override
  State<SNLogin> createState() => _SNLoginState();
}

class _SNLoginState extends State<SNLogin> {
  late final CBLoginForm _cubit = Modular.get<CBLoginForm>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WAuthHeader(
                title: 'auth_login_title'.tr(),
                subtitle: 'auth_login_subtitle'.tr(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: BlocBuilder<CBLoginForm, SLoginForm>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        if (AppConfig.useMockBackend) const _DemoCredentials(),
                        SizedBox(height: 8.h),
                        TextField(
                          onChanged: _cubit.setIdentifier,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(
                            label: 'auth_email_or_phone'.tr(),
                            icon: Icons.alternate_email_rounded,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          onChanged: _cubit.setPassword,
                          obscureText: state.obscurePassword,
                          decoration: _dec(
                            label: 'auth_password'.tr(),
                            icon: Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(state.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: _cubit.toggleObscure,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                Modular.to.pushNamed(AuthRoutes.fullForgot()),
                            child: Text('auth_forgot_password'.tr()),
                          ),
                        ),
                        if (state.error != null) ...[
                          SizedBox(height: 4.h),
                          _ErrorBanner(message: state.error!),
                        ],
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.isValid && !state.isSubmitting
                                ? () async {
                                    final ok = await _cubit.submit();
                                    if (!mounted) return;
                                    if (ok) {
                                      Modular.to.navigate(RoutesNames.homeBase);
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColorsLight.primary,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: state.isSubmitting
                                ? SizedBox(
                                    width: 20.r, height: 20.r,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.2,
                                    ),
                                  )
                                : Text('auth_login'.tr(),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    )),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('auth_no_account'.tr(),
                                style: TextStyle(fontSize: 13.sp)),
                            TextButton(
                              onPressed: () => Modular.to
                                  .pushNamed(AuthRoutes.fullRegister()),
                              child: Text('auth_register'.tr()),
                            ),
                          ],
                        ),
                      ],
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

InputDecoration _dec({required String label, required IconData icon, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    border: const OutlineInputBorder(),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColorsLight.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsLight.error, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColorsLight.error, size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppColorsLight.error, fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsLight.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsLight.accent, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('auth_demo_creds'.tr(),
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text('demo@quran.app  ·  P@ssw0rd!',
              style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace')),
          Text('test@quran.app  ·  Test1234!',
              style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
