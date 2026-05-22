import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_otp_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_otp_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_header.dart';

class SNVerifyOtp extends StatefulWidget {
  const SNVerifyOtp({super.key, required this.email});

  final String email;

  @override
  State<SNVerifyOtp> createState() => _SNVerifyOtpState();
}

class _SNVerifyOtpState extends State<SNVerifyOtp> {
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
                title: 'auth_otp_title'.tr(),
                subtitle: 'auth_otp_subtitle'.tr().replaceFirst(
                      '{{email}}',
                      widget.email,
                    ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: BlocBuilder<CBOtpForm, SOtpForm>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        TextField(
                          onChanged: _cubit.setOtp,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'auth_otp_code'.tr(),
                            border: const OutlineInputBorder(),
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
                            onPressed: state.isOtpValid && !state.isSubmitting
                                ? () async {
                                    final ok = await _cubit.verifyOnly();
                                    if (!mounted) return;
                                    if (ok) {
                                      Modular.to.pushNamed(
                                        AuthRoutes.fullReset(widget.email),
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
                                : Text('auth_verify_otp'.tr(),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    )),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'auth_demo_otp_hint'.tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColorsLight.muted,
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
