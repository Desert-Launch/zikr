import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';

class AppAlert {
  static void success(String text) {
    toastification.show(
      title: Text(text, style: TextStyle(fontSize: 14.sp), maxLines: 2),
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        color: Color(0xff00FF2E),
        linearMinHeight: 1,
        linearTrackColor: Color(0xffced4da),
      ),
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: false,
      dragToClose: true,
      applyBlurEffect: true,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      primaryColor: const Color(0xff00FF2E),
      borderRadius: BorderRadius.circular(12.rCapped(14)),
      backgroundColor: Colors.white,
    );
  }

  static void error(String text) {
    toastification.show(
      title: Text(text, style: TextStyle(fontSize: 14.sp), maxLines: 2),
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        color: Color(0xffFF002E),
        linearMinHeight: 1,
        linearTrackColor: Color(0xffced4da),
      ),
      closeOnClick: false,
      pauseOnHover: false,
      dragToClose: true,
      applyBlurEffect: true,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      primaryColor: const Color(0xffFF002E),
      borderRadius: BorderRadius.circular(12.rCapped(14)),
      backgroundColor: Colors.white,
    );
  }
}
