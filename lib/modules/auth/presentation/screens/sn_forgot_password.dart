import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_forgot_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_forgot_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_header.dart';

class SNForgotPassword extends StatefulWidget {
  const SNForgotPassword({super.key});

  @override
  State<SNForgotPassword> createState() => _SNForgotPasswordState();
}

class _SNForgotPasswordState extends State<SNForgotPassword> {
  late final CBForgotForm _cubit = Modular.get<CBForgotForm>();

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
                title: 'auth_forgot_title'.tr(),
                subtitle: 'auth_forgot_subtitle'.tr(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: BlocBuilder<CBForgotForm, SForgotForm>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        TextField(
                          onChanged: _cubit.setEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'auth_email'.tr(),
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (state.error != null) ...[
                          _ErrorBanner(message: state.error!),
                          SizedBox(height: 8.h),
                        ],
                        if (state.didSend) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColorsLight.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: AppColorsLight.success, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    color: AppColorsLight.success),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text('auth_otp_sent'.tr(),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColorsLight.success,
                                      )),
                                ),
                              ],
                            ),
                          ),
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
                                      Modular.to.pushNamed(
                                        AuthRoutes.fullOtp(state.email.trim()),
                                      );
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
                                : Text('auth_send_reset_link'.tr(),
                                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
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
