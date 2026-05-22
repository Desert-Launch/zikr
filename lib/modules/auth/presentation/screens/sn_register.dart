import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_register_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_register_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_header.dart';

class SNRegister extends StatefulWidget {
  const SNRegister({super.key});

  @override
  State<SNRegister> createState() => _SNRegisterState();
}

class _SNRegisterState extends State<SNRegister> {
  late final CBRegisterForm _cubit = Modular.get<CBRegisterForm>();

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
                title: 'auth_register_title'.tr(),
                subtitle: 'auth_register_subtitle'.tr(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: BlocBuilder<CBRegisterForm, SRegisterForm>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        TextField(
                          onChanged: _cubit.setName,
                          decoration: _dec(
                            label: 'auth_name'.tr(),
                            icon: Icons.person_outline_rounded,
                            errorText: state.name.isEmpty || state.isNameValid
                                ? null
                                : 'auth_name_invalid'.tr(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          onChanged: _cubit.setEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(
                            label: 'auth_email'.tr(),
                            icon: Icons.alternate_email_rounded,
                            errorText: state.email.isEmpty || state.isEmailValid
                                ? null
                                : 'auth_email_invalid'.tr(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          onChanged: _cubit.setPhone,
                          keyboardType: TextInputType.phone,
                          decoration: _dec(
                            label: 'auth_phone'.tr(),
                            icon: Icons.phone_outlined,
                            hint: '01XXXXXXXXX',
                            errorText: state.isPhoneValid
                                ? null
                                : 'auth_phone_invalid'.tr(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          onChanged: _cubit.setPassword,
                          obscureText: state.obscurePassword,
                          decoration: _dec(
                            label: 'auth_password'.tr(),
                            icon: Icons.lock_outline_rounded,
                            errorText: state.password.isEmpty || state.isPasswordValid
                                ? null
                                : 'auth_password_rule'.tr(),
                            suffix: IconButton(
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
                          decoration: _dec(
                            label: 'auth_confirm_password'.tr(),
                            icon: Icons.lock_outline_rounded,
                            errorText: state.confirmPassword.isEmpty || state.passwordsMatch
                                ? null
                                : 'auth_password_mismatch'.tr(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        if (state.error != null) ...[
                          _ErrorBanner(message: state.error!),
                          SizedBox(height: 8.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.isValid && !state.isSubmitting
                                ? () async {
                                    final ok = await _cubit.submit();
                                    if (!mounted) return;
                                    if (ok) {
                                      Modular.to.pushNamed(AuthRoutes.fullSuccess());
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
                                : Text('auth_register'.tr(),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    )),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('auth_have_account'.tr(),
                                style: TextStyle(fontSize: 13.sp)),
                            TextButton(
                              onPressed: () => Modular.to.pop(),
                              child: Text('auth_login'.tr()),
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

InputDecoration _dec({
  required String label,
  required IconData icon,
  Widget? suffix,
  String? errorText,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    errorText: errorText,
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
