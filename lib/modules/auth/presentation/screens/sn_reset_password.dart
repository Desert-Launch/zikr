import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_otp_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_otp_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_header.dart';

class SNResetPassword extends StatefulWidget {
  const SNResetPassword({super.key, required this.email});

  final String email;

  @override
  State<SNResetPassword> createState() => _SNResetPasswordState();
}

class _SNResetPasswordState extends State<SNResetPassword> {
  late final CBOtpForm _cubit = Modular.get<CBOtpForm>()..setEmail(widget.email);

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
                title: 'auth_reset_title'.tr(),
                subtitle: 'auth_reset_subtitle'.tr(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: BlocBuilder<CBOtpForm, SOtpForm>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        TextField(
                          onChanged: _cubit.setPassword,
                          obscureText: state.obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'auth_new_password'.tr(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                            errorText:
                                state.newPassword.isEmpty || state.isPasswordValid
                                    ? null
                                    : 'auth_password_rule'.tr(),
                            suffixIcon: IconButton(
                              icon: Icon(state.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: _cubit.toggleObscure,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          onChanged: _cubit.setConfirmPassword,
                          obscureText: state.obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'auth_confirm_password'.tr(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                            errorText:
                                state.confirmPassword.isEmpty || state.passwordsMatch
                                    ? null
                                    : 'auth_password_mismatch'.tr(),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (state.error != null) ...[
                          _ErrorBanner(message: state.error!),
                          SizedBox(height: 8.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.isValid && !state.isSubmitting
                                ? () async {
                                    final ok = await _cubit.resetPassword();
                                    if (!mounted) return;
                                    if (ok) {
                                      Modular.to.navigate(AuthRoutes.fullLogin());
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
                                : Text('auth_reset_button'.tr(),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    )),
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
      ),
    );
  }
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
